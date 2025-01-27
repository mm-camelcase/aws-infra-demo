variable "name" {
  type        = string
  description = "Gateway Name "
}

variable "subnet_ids" {
  type        = list(string) # Defines an array of strings
  description = "List of subnet IDs for the VPC Link"
}

variable "api_listener_arn" {
  type        = string
  description = "NLB listener for api"
}

variable "auth_listener_arn" {
  type        = string
  description = "NLB listener for auth"
}

variable "gateway-sg-id" {
  type        = string
  description = "gateway sg"
}

variable "cert_arn" {
  type        = string
  description = "Cert"
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resource"
}


