resource "aws_sqs_queue" "this" {
  name                       = join("-", [local.name, "upload-events"])
  visibility_timeout_seconds = 60
}

resource "aws_lambda_event_source_mapping" "routing" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.main.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.this.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.upload_event.arn}"
        }
      }
    }
  ]
}
POLICY
}
