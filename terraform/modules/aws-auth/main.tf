data "aws_caller_identity" "current" {}

locals {
  cluster_node_group_roles = [for role_arn in var.node_group_role_arns : {
    rolearn  = role_arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups = [
      "system:bootstrappers",
      "system:nodes",
    ]
    }
  ]
  cluster_admin_roles = [for role in var.cluster_admin_roles : {
    rolearn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
    groups = [
      "system:masters"
    ]
    }
  ]
  cluster_admin_users = [for user in var.cluster_admin_users : {
    userarn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"
    groups = [
      "system:masters"
    ]
    }
  ]
  aws_auth_configmap_data = {
    mapRoles    = yamlencode(concat(local.cluster_node_group_roles, local.cluster_admin_roles, var.roles))
    mapUsers    = yamlencode(concat(local.cluster_admin_users, var.users))
    mapAccounts = yamlencode(var.accounts)
  }
}

# resource "kubernetes_config_map_v1" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = local.aws_auth_configmap_data

#   lifecycle {
#     ignore_changes = [metadata[0].labels, metadata[0].annotations]
#   }
# }

resource "kubectl_manifest" "aws_auth" {
  force_conflicts = true

  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      ${indent(2, yamlencode(local.aws_auth_configmap_data))}
  YAML
}

# output "aws_auth" {
#   value = kubectl_manifest.aws_auth.yaml_body_parsed
# }
