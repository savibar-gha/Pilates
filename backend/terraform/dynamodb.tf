resource "aws_dynamodb_table" "respuestas" {
  name         = "${var.project_name}-respuestas"
  billing_mode = "PAY_PER_REQUEST" # sin costo fijo, ideal para tráfico bajo/medio
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Permite ordenar/filtrar por fecha sin escanear toda la tabla en el futuro
  attribute {
    name = "fecha"
    type = "S"
  }

  global_secondary_index {
    name            = "fecha-index"
    hash_key        = "fecha"
    projection_type = "ALL"
  }

  tags = {
    Proyecto = var.project_name
  }
}
