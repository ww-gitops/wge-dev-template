provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source  = "Terraform Managed"
      cluster = var.cluster_name
    }, var.tags)
  }
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "terraform_remote_state" "eks_core" {
  backend = "s3"

  config = {
    bucket = var.eks_core_state_bucket
    key    = var.eks_core_state_key
    region = var.region
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "vault" {
  address = var.vault_url
  token = var.vault_token
}
module "system_node_group" {
  source                    = "../../modules/node-group"
  cluster_name              = var.cluster_name
  node_group_name           = "${var.cluster_name}-system-ng"
  vpc_id                    = data.terraform_remote_state.eks_core.outputs.vpc_id
  subnet_ids                = split(",",data.terraform_remote_state.eks_core.outputs.subnet_ids)
  cluster_security_group_id = data.terraform_remote_state.eks_core.outputs.cluster_sg_id
  desired_size              = var.desired_size
  min_size                  = var.min_size
  max_size                  = var.max_size
  capacity_type             = var.capacity_type
  instance_types            = [var.instance_type]
  labels                    = { role = "system" }
  resource_tags             = var.tags
}

module "worker_node_group" {
  source                    = "../../modules/node-group"
  cluster_name              = var.cluster_name
  node_group_name           = "${var.cluster_name}-worker-ng"
  vpc_id                    = data.terraform_remote_state.eks_core.outputs.vpc_id
  subnet_ids                = split(",",data.terraform_remote_state.eks_core.outputs.subnet_ids)
  cluster_security_group_id = data.terraform_remote_state.eks_core.outputs.cluster_sg_id
  desired_size              = 0
  min_size                  = 0
  max_size                  = var.max_size
  capacity_type             = var.capacity_type
  instance_types            = [var.instance_type]
  labels                    = { role = "worker" }
  resource_tags             = var.tags
}

module "leaf_config" {
  source                 = "../../modules/leaf-config"
  cluster_name           = var.cluster_name
  cluster_ca_certificate = data.aws_eks_cluster.this.certificate_authority[0].data
  cluster_endpoint       = data.aws_eks_cluster.this.endpoint
  template_namespace     = var.template_namespace
}

module "flux_bootstrap" {
  source                  = "../../modules/flux-bootstrap"
  aws_region              = var.region
  cluster_name            = var.cluster_name
  github_owner            = var.github_owner
  repository_name         = var.repository_name
  branch                  = var.branch
  target_path             = local.flux_target_path
  commit_author           = var.git_commit_author
  commit_email            = var.git_commit_email
  use_existing_repository = true
}

data "aws_caller_identity" "current" {}

module "aws_auth" {
  source              = "../../modules/aws-auth"
  accounts            = [data.aws_caller_identity.current.account_id]
  cluster_admin_roles = local.cluster_admin_roles
  cluster_admin_users = local.cluster_admin_users
  node_group_role_arns = [
    module.system_node_group.node_group_role.arn,
    module.worker_node_group.node_group_role.arn,
  ]
}

resource "aws_autoscaling_schedule" "set-scale-to-zero-ng-worker" {
  scheduled_action_name  = "scale"
  min_size               = var.shrink ? 0 : var.min_size
  max_size               = var.shrink ? 0 : var.max_size
  desired_capacity       = var.shrink ? 0 : var.desired_size
  recurrence             = "*/5 * * * *"
  autoscaling_group_name = module.worker_node_group.node_group.resources[0].autoscaling_groups[0].name
}
