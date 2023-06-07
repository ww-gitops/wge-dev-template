output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "role_arn" {
  value = aws_iam_role.aws_efs_csi_driver.arn
}
