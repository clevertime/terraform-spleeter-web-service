# main
data "archive_file" "main" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/main/"
  output_path = "${path.module}/lambda/main.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = join("-", [local.name, "main"])
  description      = "Lambda manage upload events"
  role             = aws_iam_role.main.arn
  memory_size      = local.memory_size
  runtime          = local.runtime
  timeout          = local.timeout
  handler          = "spleeter-web-service-main.lambda_handler"
  filename         = "${path.module}/lambda/main.zip"
  source_code_hash = data.archive_file.main.output_base64sha256
  tags             = local.tags
}

resource "aws_iam_role" "main" {
  name = join("-", [local.name, "main", "lambda"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "main_basic_execution" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "main_lambda" {
  statement {
    actions = [
      "s3:List*",
      "s3:Get*",
    ]

    resources = [
      aws_s3_bucket.uploads.arn,
      join("", [aws_s3_bucket.uploads.arn, "/*"])
    ]
  }
}

resource "aws_iam_role_policy" "main" {
  name   = join("-", [local.name, "main", "lambda"])
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main_lambda.json
}
