resource "aws_cloudwatch_log_group" "main" {
  name              = var.cloudwatch_group_name
  retention_in_days = "7"

  tags = {
    Name        = var.environment
    Application = var.app_name
  }
}