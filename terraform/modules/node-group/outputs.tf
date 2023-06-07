output "node_group" {
  value = aws_eks_node_group.this
}

output "node_group_role" {
  value = aws_iam_role.eks_node_group_role
}
