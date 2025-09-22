include {
  path = find_in_parent_folders()
}

dependency "aft_main" {
  config_path = "../main"
  skip_outputs = true
}

inputs = {
  slack_notification_lambda_arn = try(dependency.aft_main.outputs.slack_notification_lambda_arn, "")
}