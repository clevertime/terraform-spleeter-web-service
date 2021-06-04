resource "aws_ecs_cluster" "this" {
  name = join("-", [local.name, "cluster"])
}

resource "aws_cloudwatch_log_group" "this" {
  name = join("", ["/ecs/", local.name, "-cluster"])
  tags = local.tags
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode(
      [
          {
              image             = "848147755445.dkr.ecr.us-west-2.amazonaws.com/spleeter-web-service-repo:latest"
              memoryReservation = 4096
              name              = join("-", [local.name, "task"])
              logConfiguration  = {
                  logDriver = "awslogs"
                  options   = {
                      awslogs-group         = join("", ["/ecs/", local.name, "-cluster"])
                      awslogs-region        = local.region
                      awslogs-stream-prefix = "ecs"
                  }
              }
          },
      ]
  )
  cpu                      = "2048"
  execution_role_arn       = aws_iam_role.processor.arn
  family                   = join("-", [local.name, "task"])
  memory                   = "6144"
  network_mode             = "awsvpc"
  requires_compatibilities = [
      "FARGATE",
  ]
  tags                     = local.tags
  task_role_arn            = aws_iam_role.processor.arn
}

resource "aws_iam_role" "processor" {
  name = join("-", [local.name, "processor", "ecs-task"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "processor_task_execution" {
  role       = aws_iam_role.processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "processor" {
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
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.processed.arn,
      join("", [aws_s3_bucket.processed.arn, "/*"])
    ]
  }

  statement {
    actions = [
      "dynamodb:List*",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }
}

resource "aws_iam_role_policy" "processor" {
  name   = join("-", [local.name, "processor", "ecs-task"])
  role   = aws_iam_role.processor.id
  policy = data.aws_iam_policy_document.processor.json
}
