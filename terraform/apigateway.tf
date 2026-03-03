resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project_name}-api"
  description = "REST API for the stock mover pipeline"

  tags = {
    Project = var.project_name
  }
}


resource "aws_api_gateway_resource" "movers" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id = aws_api_gateway_rest_api.main.root_resource_id
  path_part = "movers"
}


resource "aws_api_gateway_method" "get_movers" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = "GET"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.get_movers.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.api.invoke_arn
}


resource "aws_api_gateway_method" "options_movers" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = "OPTIONS"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}


resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}


resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.movers.id,
      aws_api_gateway_method.get_movers.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name = "prod"

  tags = {
    Project = var.project_name
  }
}


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}