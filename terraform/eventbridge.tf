resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name = "${var.project_name}-daily-trigger"
  description = "Triggers ingestion Lambda daily after market close"
  schedule_expression = "cron(30 23 * * ? *)"  # 6:30pm EST daily

  tags = {
    Project = var.project_name
  }
}


resource "aws_cloudwatch_event_target" "invoke_ingestion" {
  rule = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "ingestion-lambda"
  arn = aws_lambda_function.ingestion.arn
}


resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowEventBridgeInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_trigger.arn
}