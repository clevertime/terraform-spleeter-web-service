resource "aws_sfn_state_machine" "this" {
  name     = join("-", [local.name, "processor"])
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "${local.name} sfn",
  "StartAt": "validate",
  "States": {
    "validate": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.validate.arn}",
      "InputPath": "$",
      "Next": "processor",
      "ResultPath": "$",
      "Retry": [
        {
          "ErrorEquals": ["States.Timeout"],
          "IntervalSeconds": 3,
          "MaxAttempts": 1,
          "BackoffRate": 1.5
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [ "States.ALL" ],
          "Next": "fail_state"
        }
      ]
    },
    "processor": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.processor.arn}",
      "InputPath": "$",
      "Next": "final_state",
      "Retry": [
        {
          "ErrorEquals": ["States.Timeout"],
          "IntervalSeconds": 3,
          "MaxAttempts": 1,
          "BackoffRate": 1.5
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [ "States.ALL" ],
          "Next": "final_state"
        }
      ]
    },
    "final_state": {
      "Type": "Succeed"
    },
    "fail_state": {
      "Type": "Fail",
      "Cause": "Resulted in Error!"
    }
  }
}
EOF
}

resource "aws_iam_role" "sfn" {
  name = join("-", [local.name, "sfn"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "sfn" {
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
      "lambda:InvokeFunction"
    ]

    resources = [
      aws_lambda_function.validate.arn,
      aws_lambda_function.processor.arn
    ]
  }
}

resource "aws_iam_role_policy" "sfn" {
  name   = join("-", [local.name, "sfn"])
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn.json
}
