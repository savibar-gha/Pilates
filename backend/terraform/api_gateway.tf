resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [var.allowed_origin, regex("^https://[^/]+", var.report_callback_url)]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# --- POST /respuestas -> ingest ---
resource "aws_apigatewayv2_integration" "ingest" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingest.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_respuestas" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /respuestas"
  target    = "integrations/${aws_apigatewayv2_integration.ingest.id}"
}

resource "aws_lambda_permission" "allow_apigw_ingest" {
  statement_id  = "AllowAPIGatewayInvokeIngest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# --- GET /reportes -> report (protegido con Cognito) ---
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.report_client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.report_users.id}"
  }
}

resource "aws_apigatewayv2_integration" "report" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.report.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_reportes" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /reportes"
  target             = "integrations/${aws_apigatewayv2_integration.report.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_lambda_permission" "allow_apigw_report" {
  statement_id  = "AllowAPIGatewayInvokeReport"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
