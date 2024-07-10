variable "role_name_prefix" {
    type = string
    default = ""
}

variable "account_id" {
    type = string
}

variable "kubernetes_oidc_issure" {
    type = string
}

variable "irsa" {
    type = list(object({
        name = string
        kubernetes_namespace = string
        iam_role_policy_statements = list(object({
            Effect = string
            Action = list(string)
            Resource = list(string)
        }))
    }))
}