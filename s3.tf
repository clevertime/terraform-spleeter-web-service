resource "aws_s3_bucket" "uploads" {
  bucket = join("-", [local.name, "uploads"])

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = var.ttl
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

output "s3_uploads_bucket" {
  value = aws_s3_bucket.uploads.id
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  topic {
    topic_arn = aws_sns_topic.upload_event.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.upload_event]
}

resource "aws_sns_topic" "upload_event" {
  name = join("-", [local.name, "upload-event"])
}

resource "aws_sns_topic_policy" "upload_event" {
  arn = aws_sns_topic.upload_event.arn
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect"    = "Allow",
          "Principal" = { "Service" : "s3.amazonaws.com" },
          "Action"    = "SNS:Publish",
          "Resource"  = aws_sns_topic.upload_event.arn,
          "Condition" = {
            "ArnLike" = {
              "aws:SourceArn" = aws_s3_bucket.uploads.arn
            }
          }
        }
      ]
    }
  )
}

data "aws_iam_policy_document" "sns_topic_upload_event" {
  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.upload_event.arn
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.uploads.arn
      ]
    }
  }
}

resource "aws_sns_topic_subscription" "upload_event_sqs" {
  topic_arn = aws_sns_topic.upload_event.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

resource "aws_s3_bucket" "processed" {
  bucket = join("-", [local.name, "processed"])

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = var.ttl
    }
  }
}

output "s3_processed_bucket" {
  value = aws_s3_bucket.processed.id
}
