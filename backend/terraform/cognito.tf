resource "aws_cognito_user_pool" "report_users" {
  name = "${var.project_name}-report-users"

  # Solo vos das de alta usuarios (staff), no hay auto-registro público
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]
}

# Dominio del Hosted UI, ej: https://maspilates-encuesta-report.auth.us-east-1.amazoncognito.com
resource "aws_cognito_user_pool_domain" "report_domain" {
  domain       = "${var.project_name}-report"
  user_pool_id = aws_cognito_user_pool.report_users.id
}

resource "aws_cognito_user_pool_client" "report_client" {
  name         = "${var.project_name}-report-client"
  user_pool_id = aws_cognito_user_pool.report_users.id

  generate_secret = false # SPA pública (JS en el navegador), sin secret

  allowed_oauth_flows                 = ["implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                = ["openid", "email"]

  callback_urls = [var.report_callback_url]
  logout_urls   = [var.report_callback_url]

  supported_identity_providers = ["COGNITO"]
}

output "cognito_hosted_ui_domain" {
  value = "${aws_cognito_user_pool_domain.report_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.report_client.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.report_users.id
}
