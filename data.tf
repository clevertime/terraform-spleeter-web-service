data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  account_id  = data.aws_caller_identity.this.account_id
  region      = data.aws_region.this.name
  name        = var.custom_name == null ? trimprefix(join("-", [var.prefix, "spleeter-web-service"]), "-") : var.custom_name
  memory_size = 256
  timeout     = 60
  runtime     = "python3.8"
}
