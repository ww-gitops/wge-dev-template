data "aws_iam_policy_document" "aws_efs_csi_driver_assume_role" {
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

resource "aws_iam_role" "aws_efs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.aws_efs_csi_driver_assume_role.json
  name               = "${var.cluster_name}-aws-efs-csi-driver"
}

data "aws_iam_policy_document" "aws_efs_csi_driver" {
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "aws_efs_csi_driver" {
  name   = "${var.cluster_name}-aws-efs-csi-driver"
  policy = data.aws_iam_policy_document.aws_efs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "aws_efs_csi_driver" {
  role       = aws_iam_role.aws_efs_csi_driver.name
  policy_arn = aws_iam_policy.aws_efs_csi_driver.arn
}

resource "aws_security_group" "efs_sg" {
  name   = "${var.cluster_name}-efs-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "efs_ingress_nfs" {
  cidr_blocks       = var.allowed_cidr_blocks
  from_port         = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.efs_sg.id
  to_port           = 2049
  type              = "ingress"
}

resource "aws_efs_file_system" "this" {
  performance_mode = var.performance_mode

  tags = {
    Name = "${var.cluster_name}-efs"
  }
}

resource "aws_efs_mount_target" "targets" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "gitlab_repository_file" "aws_efs_csi_driver" {
  count = var.create_release_file == true ? 1 : 0

  project        = var.repository_id
  branch         = var.branch
  file_path      = var.file_path
  author_email   = var.commit_email
  author_name    = var.commit_author
  commit_message = "Add ${var.file_path}"
  content = base64encode(templatefile("${path.module}/templates/helmrelease.tftpl", {
    name                     = "aws-efs-csi-driver"
    namespace                = var.namespace
    create_namespace         = var.create_namespace
    repository_name          = "aws-efs-csi-driver"
    repository_url           = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
    repository_secret        = null
    repository_sync_interval = "1h"
    chart                    = "aws-efs-csi-driver"
    version                  = var.chart_version
    depends_on               = []
    extra_manifests          = null
    values = chomp(<<-EOF
controller:
  serviceAccount:
    create: true
    name: ${var.service_account}
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.aws_efs_csi_driver.arn}
storageClasses:
  - name: efs-sc
    parameters:
      provisioningMode: efs-ap
      fileSystemId: ${aws_efs_file_system.this.id}
      directoryPerms: "700"
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
