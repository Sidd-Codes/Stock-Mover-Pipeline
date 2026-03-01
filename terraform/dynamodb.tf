resource "aws_dynamodb_table" "top_movers" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "date"

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}