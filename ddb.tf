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

  attribute {
    name = "key"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name               = "ObjectKey"
    hash_key           = "key"
    write_capacity     = var.ddb_write_capacity
    read_capacity      = var.ddb_read_capacity
    projection_type    = "INCLUDE"
    non_key_attributes = ["id"]
  }

  tags = local.tags
}

output "status_dynamo_table" {
  value = aws_dynamodb_table.this.name
}
