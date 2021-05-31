# Master lambda
data "archive_file" "avm-master" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/avm-master/"
  output_path = "${path.module}/lambda/avm-master.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = join("-", [var.name, "main"])
  description      = "Lambda manage upload events"
  role             = aws_iam_role.lambda.arn
  memory_size      = local.memory_size
  runtime          = local.runtime
  timeout          = local.timeout
  handler          = "avm-master.lambda_handler"
  filename         = "${path.module}/lambda/avm-master.zip"
  source_code_hash = data.archive_file.avm-master.output_base64sha256
  layers           = [aws_lambda_layer_version.avm-lambda-layer.arn]
  tags             = local.tags

  environment {
    variables = {
      STATEMACHINE_ARN = aws_sfn_state_machine.avm.id
    }
  }
}
