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
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.main.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_uploads_to_lambda_main]
}

resource "aws_lambda_permission" "s3_uploads_to_lambda_main" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
  source_account = local.account_id
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
