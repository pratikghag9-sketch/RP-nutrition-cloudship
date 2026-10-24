resource "aws_secretsmanager_secret" "this" {
  for_each = var.secret_names

  name                    = each.value
  recovery_window_in_days = var.recovery_window_in_days
}
