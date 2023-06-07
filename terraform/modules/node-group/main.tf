resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids
  ami_type        = var.ami_type
  instance_types  = var.instance_types
  capacity_type   = var.capacity_type
  labels          = var.labels
  tags            = var.tags

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_launch_template" "this" {
  name = "${var.node_group_name}-lt"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = true
    }
  }

  ebs_optimized = true

  # metadata_options {
  #   http_endpoint               = "enabled"
  #   http_tokens                 = "required"
  #   http_put_response_hop_limit = 1
  #   instance_metadata_tags      = "enabled"
  # }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Name = "${var.node_group_name}-node"
    }, var.resource_tags)

  }

  tag_specifications {
    resource_type = "volume"

    tags = merge({
      Name = "${var.node_group_name}-volume"
    }, var.resource_tags)
  }

}

resource "aws_autoscaling_schedule" "autoscaling" {
  for_each = { for a in var.autoscaling : a.schedule_name => a }

  scheduled_action_name  = each.value.schedule_name
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
  min_size               = each.value.min_size
  max_size               = each.value.max_size
  desired_capacity       = each.value.desired_size
  recurrence             = each.value.recurrence
  time_zone              = each.value.time_zone
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.node_group_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = var.additional_policy_arns

  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = each.value
}

resource "aws_security_group" "eks_node_group_sg" {
  name        = "${var.node_group_name}-sg"
  description = "Security Group for ${var.cluster_name} worker nodes"
  vpc_id      = var.vpc_id

  tags = merge({
    Name                                        = "${var.node_group_name}-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }, var.tags)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "eks_node_group_ingress_self" {
  description              = "Allow worker nodes to worker nodes"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node_group_sg.id
  source_security_group_id = aws_security_group.eks_node_group_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_group_ingress_cluster" {
  description              = "Allow worker nodes inbound from control plane nodes"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_group_sg.id
  source_security_group_id = var.cluster_security_group_id
  to_port                  = 65535
  type                     = "ingress"
}
