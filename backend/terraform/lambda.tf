data "archive_file" "ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/ingest"
  output_path = "${path.module}/../lambda/ingest.zip"
}

data "archive_file" "report_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/report"
  output_path = "${path.module}/../lambda/report.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name    = "${var.project_name}-ingest"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.ingest_zip.output_path
  source_code_hash = data.archive_file.ingest_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.respuestas.name
      ALLOWED_ORIGIN = var.allowed_origin
    }
  }
}

resource "aws_lambda_function" "report" {
  function_name    = "${var.project_name}-report"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.report_zip.output_path
  source_code_hash = data.archive_file.report_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.respuestas.name
      ALLOWED_ORIGIN = var.allowed_origin
    }
  }
}
