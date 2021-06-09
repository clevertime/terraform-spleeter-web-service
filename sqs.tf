# resource "aws_sqs_queue" "this" {
#   name                       = join("-", [var.name, "queue"])
#   visibility_timeout_seconds = 60
#
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.deadletter.arn
#     maxReceiveCount     = 1
#   })
# }
#
# resource "aws_sqs_queue" "deadletter" {
#   name                       = join("-", [var.name, "dlq-queue"])
#   visibility_timeout_seconds = 60
#   message_retention_seconds  = 1209600
# }
#
# resource "aws_lambda_event_source_mapping" "routing" {
#   event_source_arn = aws_sqs_queue.this.arn
#   function_name    = aws_lambda_function.main.arn
#   batch_size       = 10
#   enabled          = true
# }
