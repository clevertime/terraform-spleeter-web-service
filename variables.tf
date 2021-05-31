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
