resource "aws_cloudwatch_log_group" "monit" {
  name              = var.cloudwatch_group_name
  retention_in_days = "7"

  tags = var.default_tags
}