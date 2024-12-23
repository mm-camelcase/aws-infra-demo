output "available_azs" {
  value = slice(data.aws_availability_zones.available.names, 0, 2)
}

