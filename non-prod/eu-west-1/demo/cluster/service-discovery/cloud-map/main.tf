resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.name
  description = "CloudMap namespace for ${var.name}"
  vpc         = var.vpc_id
  tags        = var.tags
}



resource "aws_service_discovery_service" "user_service" {
  name = var.user_service_name
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags        = var.tags
}

resource "aws_service_discovery_service" "todo_service" {
  name = var.todo_service_name
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags        = var.tags
}



resource "aws_service_discovery_service" "core-db" {
  name = var.core_db_name
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags        = var.tags
}