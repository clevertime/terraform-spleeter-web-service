resource "aws_dynamodb_table" "this" {
  name           = join("-", [local.name, "data"])
  billing_mode   = "PROVISIONED"
  read_capacity  = var.ddb_read_capacity
  write_capacity = var.ddb_write_capacity
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.tags
}
