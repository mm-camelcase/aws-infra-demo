variable "name" {
  type        = string
  description = "Name for the CloudMap namespace"
}

variable "vpc_id" {
  type        = string
}


variable "user_service_name" {
  type        = string
  description = "Service name for user-service in CloudMap"
  default     = "user-service"
}


variable "core_db_name" {
  type        = string
  description = "Service name for user-service in CloudMap"
  default     = "core-db"
}


variable "tags" {
  type        = map(string)
  description = "Tags for the resource"
}
