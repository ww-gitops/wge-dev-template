data "aws_iam_policy_document" "aws_ebs_csi_driver_assume_role" {
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

resource "aws_iam_role" "aws_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.aws_ebs_csi_driver_assume_role.json
  name               = "${var.cluster_name}-aws-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "aws_ebs_csi_driver" {
  role       = aws_iam_role.aws_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "gitlab_repository_file" "aws_ebs_csi_driver" {
  count = var.create_release_file == true ? 1 : 0

  project        = var.repository_id
  branch         = var.branch
  file_path      = var.file_path
  author_email   = var.commit_email
  author_name    = var.commit_author
  commit_message = "Add ${var.file_path}"
  content = base64encode(templatefile("${path.module}/templates/helmrelease.tftpl", {
    name                     = "aws-ebs-csi-driver"
    namespace                = var.namespace
    create_namespace         = var.create_namespace
    repository_name          = "aws-ebs-csi-driver"
    repository_url           = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
    repository_secret        = null
    repository_sync_interval = "1h"
    chart                    = "aws-ebs-csi-driver"
    version                  = var.chart_version
    depends_on               = []
    extra_manifests          = null
    values = chomp(<<-EOF
controller:
  serviceAccount:
    create: true
    name: ${var.service_account}
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.aws_ebs_csi_driver.arn}
storageClasses:
  - name: ebs-sc
    volumeBindingMode: WaitForFirstConsumer
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
