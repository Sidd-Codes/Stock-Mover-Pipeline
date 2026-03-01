resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Project = var.project_name
  }
}