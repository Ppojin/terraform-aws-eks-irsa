data "aws_caller_identity" "current" {}

#  _____  ___  ___  ___ ______      _      
# |_   _|/ _ \ |  \/  | | ___ \    | |     
#   | | / /_\ \| .  . | | |_/ /___ | | ___ 
#   | | |  _  || |\/| | |    // _ \| |/ _ \
#  _| |_| | | || |  | | | |\ \ (_) | |  __/
#  \___/\_| |_/\_|  |_/ \_| \_\___/|_|\___|
#                   ______                 
#                  |______|                

resource "aws_iam_role" "role" {
  for_each = { for _map in var.irsa : _map.name => _map }

  name = "${var.role_name_prefix}-${each.value.name}-role"
  
  inline_policy {
    name = "${var.role_name_prefix}-${each.value.name}-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = each.value.iam_role_policy_statements
    })
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.kubernetes_oidc_issure}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.kubernetes_oidc_issure}:aud" = "sts.amazonaws.com"
            "${var.kubernetes_oidc_issure}:sub" = "system:serviceaccount:${each.value.kubernetes_namespace}:${each.value.name}-irsa"
          }
        }
      }
    ]
  })
}

#  _____                 _           ___                            _   
# /  ___|               (_)         / _ \                          | |  
# \ `--.  ___ _ ____   ___  ___ ___/ /_\ \ ___ ___ ___  _   _ _ __ | |_ 
#  `--. \/ _ \ '__\ \ / / |/ __/ _ \  _  |/ __/ __/ _ \| | | | '_ \| __|
# /\__/ /  __/ |   \ V /| | (_|  __/ | | | (_| (_| (_) | |_| | | | | |_ 
# \____/ \___|_|    \_/ |_|\___\___\_| |_/\___\___\___/ \__,_|_| |_|\__|

resource "kubernetes_manifest" "servcie_account" {
  for_each = { for _map in var.irsa : _map.name => _map }

  depends_on = [ aws_iam_role.role ]

  manifest  = {
    apiVersion = "v1"
    kind = "ServiceAccount"
    metadata = {
      name = "${each.value.name}-irsa"
      namespace = each.value.kubernetes_namespace
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.role[each.value.name].arn
      }
    }
  }
}
