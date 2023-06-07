data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }

    principals {
      identifiers = [var.cluster_oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role.json
  name               = "${var.cluster_name}-aws-load-balancer-controller"
}

data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${var.cluster_name}-aws-load-balancer-controller"
  policy = data.http.aws_load_balancer_controller_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "gitlab_repository_file" "aws_load_balancer_controller" {
  count = var.create_release_file == true ? 1 : 0

  project        = var.repository_id
  branch         = var.branch
  file_path      = var.file_path
  author_email   = var.commit_email
  author_name    = var.commit_author
  commit_message = "Add ${var.file_path}"
  content = base64encode(templatefile("${path.module}/templates/helmrelease.tftpl", {
    name                     = "aws-load-balancer-controller"
    namespace                = var.namespace
    create_namespace         = var.create_namespace
    repository_name          = "eks-charts"
    repository_url           = "https://aws.github.io/eks-charts"
    repository_secret        = null
    repository_sync_interval = "1h"
    chart                    = "aws-load-balancer-controller"
    version                  = var.chart_version
    depends_on               = []
    extra_manifests          = null
    values = chomp(<<-EOF
clusterName: ${var.cluster_name}
serviceAccount:
  create: true
  name: ${var.service_account}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.aws_load_balancer_controller.arn}
image:
  repository: 602401143452.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/amazon/aws-load-balancer-controller
EOF
    )
  }))

  lifecycle {
    precondition {
      condition     = var.repository_id != null
      error_message = "The repository_id must be provided."
    }

    precondition {
      condition     = var.file_path != null
      error_message = "The file_path must be provided."
    }
  }
}
