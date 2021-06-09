resource "aws_apigatewayv2_api" "this" {
  api_key_selection_expression = "$request.header.x-api-key"
  name                         = local.name
  protocol_type                = "HTTP"
  route_selection_expression   = "$request.method $request.path"
  tags                         = local.tags

  cors_configuration {
    allow_credentials = false
    allow_headers = [
      "*",
    ]
    allow_methods = [
      "DELETE",
      "GET",
      "OPTIONS",
      "POST",
    ]
    allow_origins = [
      "*",
    ]
    max_age = 0
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags

  default_route_settings {
    data_trace_enabled       = false
    detailed_metrics_enabled = false
    throttling_burst_limit   = 0
    throttling_rate_limit    = 0
  }
}

locals {
  api_integrations = {
    upload = {
      "method" = "GET",
      "path"   = "uploads"
    }
  }
}

resource "aws_apigatewayv2_integration" "upload" {
  api_id                 = aws_apigatewayv2_api.this.id
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_lambda_permission" "apigw_to_upload_lambda" {
    action         = "lambda:InvokeFunction"
    function_name  = aws_lambda_function.upload.arn
    principal      = "apigateway.amazonaws.com"
    source_arn     = join("/", [aws_apigatewayv2_api.this.execution_arn, "*", local.api_integrations["upload"].method, local.api_integrations["upload"].path])
    statement_id   = "AllowExecutionFromAPIGW"
    source_account = local.account_id
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = join("", [local.api_integrations["upload"].method, " /", local.api_integrations["upload"].path])
  target    = join("/", ["integrations", aws_apigatewayv2_integration.upload.id])
}
