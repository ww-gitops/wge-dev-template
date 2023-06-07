data "aws_iam_policy_document" "tf_controller_assume_role" {
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

resource "aws_iam_role" "tf_controller" {
  assume_role_policy = data.aws_iam_policy_document.tf_controller_assume_role.json
  name               = "${var.cluster_name}-tf-controller"
}

resource "aws_iam_role_policy_attachment" "tf_controller" {
  role       = aws_iam_role.tf_controller.name
  policy_arn = var.policy_arn
}

resource "gitlab_repository_file" "tf_controller" {
  count = var.create_release_file == true ? 1 : 0

  project        = var.repository_id
  branch         = var.branch
  file_path      = var.file_path
  author_email   = var.commit_email
  author_name    = var.commit_author
  commit_message = "Add ${var.file_path}"
  content = base64encode(templatefile("${path.module}/templates/helmrelease.tftpl", {
    name                     = "tf-controller"
    namespace                = var.namespace
    create_namespace         = var.create_namespace
    repository_name          = "tf-controller"
    repository_url           = "https://weaveworks.github.io/tf-controller"
    repository_secret        = null
    repository_sync_interval = "1h"
    create_repository        = true
    chart                    = "tf-controller"
    version                  = var.chart_version
    depends_on               = []
    extra_manifests          = null
    values = chomp(<<-EOF
%{~if length(var.image_pull_secrets) > 0~}
imagePullSecrets:
%{~for secret in var.image_pull_secrets~}
  - ${secret}
%{~endfor~}
%{~endif~}
runner:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.tf_controller.arn}
  grpc:
    maxMessageSize: ${var.runner_max_grpc_size}
%{if var.runner_image_repository != null || var.runner_image_tag != null~}
  image:
    %{~if var.runner_image_repository != null~}
    repository: ${var.runner_image_repository}
    %{~endif~}
    %{~if var.runner_image_tag != null~}
    tag: ${var.runner_image_tag}
    %{~endif~}
%{~endif~}
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
