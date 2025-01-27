# ----------------------
# Outputs
# ----------------------

output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.main_api.api_endpoint
  description = "The API Gateway endpoint URL."
}

output "ecs_custom_domain" {
  value = aws_apigatewayv2_domain_name.ecs_domain.domain_name
  description = "The custom domain name for ECS service."
}

output "auth_custom_domain" {
  value = aws_apigatewayv2_domain_name.auth_domain.domain_name
  description = "The custom domain name for Auth service."
}