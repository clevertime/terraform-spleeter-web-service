# meta
variable "custom_name" {
  description = "override name to use when naming resources"
  default     = null
}

variable "prefix" {
  description = "add prefix to default name i.e. 'prefix-spleeter-web-service'"
  default     = ""
}

variable "tags" {
  default = {}
}

# ddb
variable "ddb_read_capacity" {
  default = 2
}

variable "ddb_write_capacity" {
  default = 2
}

# ecs
variable "subnets" {}
