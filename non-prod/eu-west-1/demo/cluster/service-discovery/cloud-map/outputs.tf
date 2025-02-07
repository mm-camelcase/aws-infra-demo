output "private_dns_namespace_arn" {
  value = aws_service_discovery_private_dns_namespace.this.arn
}


output "todo_service_discovery_arn" {
  value = aws_service_discovery_service.todo_service.arn
}

output "todo_service_discovery_url" {
  value = format("%s.%s", var.todo_service_name, var.name)
}

output "core_db_discovery_arn" {
  value = aws_service_discovery_service.core-db.arn
}

output "core_db_discovery_url" {
  value = format("%s.%s", var.core_db_name, var.name)
}
