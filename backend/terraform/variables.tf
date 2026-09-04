variable "aws_region" {
  description = "Región de AWS donde se despliega todo"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base usado para nombrar los recursos"
  type        = string
  default     = "maspilates-encuesta"
}

variable "allowed_origin" {
  description = "Origen permitido para CORS (el sitio de GitHub Pages)"
  type        = string
  default     = "https://savibar-gha.github.io"
}

variable "report_callback_url" {
  description = <<-EOT
    URL completa de report.html a la que Cognito redirige después del login
    (ej: https://xxxxxxxx.cloudfront.net/report.html).
    En el primer 'apply' todavía no existe (CloudFront no está creado) —
    dejá el default y corré 'terraform apply' de nuevo con el valor real
    una vez que tengas el dominio de CloudFront (ver README, paso 2 pasadas).
  EOT
  type    = string
  default = "https://localhost/report.html"
}


