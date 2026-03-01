variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name all resources consistently"
  type        = string
  default     = "stock-pipeline"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table storing daily top movers"
  type        = string
  default     = "top_movers"
}

variable "watchlist" {
  description = "List of stock tickers to track"
  type        = list(string)
  default     = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
}