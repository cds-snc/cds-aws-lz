resource "aws_controltower_control" "this" {
  for_each           = var.ou_arns
  target_identifier  = each.value
  control_identifier = "arn:aws:controltower:ca-central-1::control/${var.identifier}"
}
