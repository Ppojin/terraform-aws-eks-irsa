output "role" {
    value = aws_iam_role.role
}

output "servic_account" {
    value = kubernetes_manifest.servcie_account
}
