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
      "Next": "process",
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
    "process": {
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Parameters": {
        "LaunchType": "FARGATE",
        "Cluster": "${aws_ecs_cluster.this.arn}",
        "TaskDefinition": "${aws_ecs_task_definition.this.arn}",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": ${jsonencode(var.subnets)},
            "AssignPublicIp": "DISABLED"
          }
        },
        "Overrides": {
          "ContainerOverrides": [
            {
              "Name": "${join("-", [local.name, "task"])}",
              "Environment": [
                {
                  "Name": "INPUT_S3_BUCKET",
                  "Value.$": "$.bucket"
                },
                {
                  "Name": "INPUT_S3_KEY",
                  "Value.$": "$.key"
                },
                {
                  "Name": "PROCESS_ID",
                  "Value.$": "$.process_id"
                },
                {
                  "Name": "DDB_TABLE_NAME",
                  "Value.$": "$.status_table_name"
                }
              ]
            }
          ]
        }
      },
      "Next": "final_state",
      "Catch": [
          {
            "ErrorEquals": [ "States.ALL" ],
            "Next": "fail_state"
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
      aws_lambda_function.validate.arn
    ]
  }

  statement {
    actions = [
      "ecs:RunTask"
    ]

    resources = [
      aws_ecs_task_definition.this.arn
    ]
  }

  statement {
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.processor.arn
    ]
  }

  statement {
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]

    resources = [
      join(":", ["arn:aws:events", local.region, local.account_id, "rule/StepFunctionsGetEventsForECSTaskRule"])
    ]
  }
}

resource "aws_iam_role_policy" "sfn" {
  name   = join("-", [local.name, "sfn"])
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn.json
}
