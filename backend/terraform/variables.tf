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
