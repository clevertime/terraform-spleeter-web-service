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

  environment {
    variables = {
      STATEMACHINE_ARN = aws_sfn_state_machine.this.arn,
      DDB_TABLE_NAME   = aws_dynamodb_table.this.name
      TTL              = var.ttl
    }
  }
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

  statement {
    actions = [
      "states:Start*"
    ]

    resources = [
      aws_sfn_state_machine.this.arn
    ]
  }

  statement {
    actions = [
      "dynamodb:List*",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }
}

resource "aws_iam_role_policy" "main" {
  name   = join("-", [local.name, "main", "lambda"])
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main_lambda.json
}

# validate
data "archive_file" "validate" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/validate/"
  output_path = "${path.module}/lambda/validate.zip"
}

resource "aws_lambda_function" "validate" {
  function_name    = join("-", [local.name, "validate"])
  description      = "Lambda manage upload events"
  role             = aws_iam_role.validate.arn
  memory_size      = local.memory_size
  runtime          = local.runtime
  timeout          = local.timeout
  handler          = "spleeter-web-service-validate.lambda_handler"
  filename         = "${path.module}/lambda/validate.zip"
  source_code_hash = data.archive_file.validate.output_base64sha256
  tags             = local.tags

  environment {
    variables = {
      DDB_TABLE_NAME = aws_dynamodb_table.this.name
    }
  }
}

resource "aws_iam_role" "validate" {
  name = join("-", [local.name, "validate", "lambda"])

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

resource "aws_iam_role_policy_attachment" "validate_basic_execution" {
  role       = aws_iam_role.validate.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "validate_lambda" {
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

  statement {
    actions = [
      "dynamodb:List*",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }
}

resource "aws_iam_role_policy" "validate" {
  name   = join("-", [local.name, "validate", "lambda"])
  role   = aws_iam_role.validate.id
  policy = data.aws_iam_policy_document.validate_lambda.json
}

# api integrations

# upload
data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/upload/"
  output_path = "${path.module}/lambda/upload.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = join("-", [local.name, "upload"])
  description      = "Lambda manage upload events"
  role             = aws_iam_role.upload.arn
  memory_size      = local.memory_size
  runtime          = "nodejs12.x"
  timeout          = local.timeout
  handler          = "app.handler"
  filename         = "${path.module}/lambda/upload.zip"
  source_code_hash = data.archive_file.upload.output_base64sha256
  tags             = local.tags

  environment {
    variables = {
      "UploadBucket" = "sam-app-s3uploadbucket-15hglhoknqk4a"
    }
  }
}

resource "aws_iam_role" "upload" {
  name = join("-", [local.name, "upload", "lambda"])

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

resource "aws_iam_role_policy_attachment" "upload_basic_execution" {
  role       = aws_iam_role.upload.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "upload_lambda" {
  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.uploads.arn,
      join("", [aws_s3_bucket.uploads.arn, "/*"])
    ]
  }
}

resource "aws_iam_role_policy" "upload" {
  name   = join("-", [local.name, "upload", "lambda"])
  role   = aws_iam_role.upload.id
  policy = data.aws_iam_policy_document.upload_lambda.json
}
