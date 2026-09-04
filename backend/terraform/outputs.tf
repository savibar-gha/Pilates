output "api_base_url" {
  description = "URL base del API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.respuestas.name
}
