data "aws_region" "current" {}

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
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

resource "aws_iam_role" "cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json
  name               = "${var.cluster_name}-cluster-autoscaler"
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${var.cluster_name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "gitlab_repository_file" "cluster_autoscaler" {
  count = var.create_release_file == true ? 1 : 0

  project        = var.repository_id
  branch         = var.branch
  file_path      = var.file_path
  author_email   = var.commit_email
  author_name    = var.commit_author
  commit_message = "Add ${var.file_path}"
  content = base64encode(templatefile("${path.module}/templates/helmrelease.tftpl", {
    name                     = "cluster-autoscaler"
    namespace                = var.namespace
    create_namespace         = var.create_namespace
    repository_name          = "autoscaler"
    repository_url           = "https://kubernetes.github.io/autoscaler"
    repository_secret        = null
    repository_sync_interval = "1h"
    chart                    = "cluster-autoscaler"
    version                  = var.chart_version
    depends_on               = []
    extra_manifests          = null
    values = chomp(<<-EOF
cloudProvider: aws
awsRegion: ${data.aws_region.current.name}
autoDiscovery:
  clusterName: ${var.cluster_name}
rbac:
  serviceAccount:
    name: ${var.service_account}
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.cluster_autoscaler.arn}
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
