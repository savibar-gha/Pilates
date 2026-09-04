data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
    ]
    resources = [
      aws_dynamodb_table.respuestas.arn,
      "${aws_dynamodb_table.respuestas.arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "${var.project_name}-dynamodb-access"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}
