output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value = aws_dynamodb_table.top_movers.name
}

output "aws_region" {
  description = "Region everything was deployed into"
  value = var.aws_region
}

output "api_gateway_url" {
  description = "Base URL for the REST API"
  value = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/movers"
}


output "frontend_url" {
  description = "Live URL for the frontend"
  value = "http://${aws_s3_bucket.frontend.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}