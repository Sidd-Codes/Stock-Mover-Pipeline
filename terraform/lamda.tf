data "archive_file" "ingestion_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/ingestion/handler.py"
  output_path = "${path.module}/../lambda/ingestion/ingestion.zip"
}


resource "aws_lambda_function" "ingestion" {
  function_name    = "${var.project_name}-ingestion"
  filename         = data.archive_file.ingestion_zip.output_path
  source_code_hash = data.archive_file.ingestion_zip.output_base64sha256
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      SECRET_NAME    = "stock-pipeline/api-key"
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tags = {
    Project = var.project_name
  }
}
