output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.top_movers.name
}

output "aws_region" {
  description = "Region everything was deployed into"
  value       = var.aws_region
}