# ----------------------
# VPC Link
# ----------------------
resource "aws_apigatewayv2_vpc_link" "my_vpc_link" {
  name = var.name

  //subnet_ids = [
  //aws_subnet.subnet1.id,
  //aws_subnet.subnet2.id
  //]

  subnet_ids = var.subnet_ids
  security_group_ids = [var.gateway-sg-id]
  tags = var.tags
}

# ----------------------
# API Gateway
# ----------------------
resource "aws_apigatewayv2_api" "main_api" {
  name                     = var.name
  protocol_type            = "HTTP"
  //route_selection_expression = "${request.method} ${request.path}"
  tags = var.tags
}

# ----------------------
# Integrations
# ----------------------

# Integration for ECS service
resource "aws_apigatewayv2_integration" "ecs_integration" {
  api_id                = aws_apigatewayv2_api.main_api.id
  integration_type = "HTTP_PROXY"
  connection_type       = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.my_vpc_link.id
  integration_uri       = var.api_listener_arn
  integration_method    = "ANY"
  timeout_milliseconds  = 12000
  
}

# Integration for Auth service
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                = aws_apigatewayv2_api.main_api.id
  integration_type = "HTTP_PROXY"
  connection_type       = "VPC_LINK"
  
  connection_id           = aws_apigatewayv2_vpc_link.my_vpc_link.id
  integration_uri       = var.auth_listener_arn
  integration_method    = "ANY"
  timeout_milliseconds  = 12000
  
}

# ----------------------
# Routes
# ----------------------

# Route for ECS service
resource "aws_apigatewayv2_route" "ecs_route" {
  api_id      = aws_apigatewayv2_api.main_api.id
  route_key   = "ANY /ecs-service/*"
  target      = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
  
}

# Route for Auth service
resource "aws_apigatewayv2_route" "auth_route" {
  api_id      = aws_apigatewayv2_api.main_api.id
  route_key   = "ANY /auth-service/*"
  target      = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
  
}

# ----------------------
# Stages
# ----------------------

# Create a default stage for the API
resource "aws_apigatewayv2_stage" "main_stage" {
  api_id      = aws_apigatewayv2_api.main_api.id
  name        = "$default"
  auto_deploy = true
  tags = var.tags
}

# ----------------------
# Custom Domains
# ----------------------

# Custom domain for ECS service
resource "aws_apigatewayv2_domain_name" "ecs_domain" {
  domain_name = "api.camelcase.club"
  domain_name_configuration {
    certificate_arn = var.cert_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  tags = var.tags
}

# Custom domain for Auth service
resource "aws_apigatewayv2_domain_name" "auth_domain" {
  domain_name = "auth.camelcase.club"
  domain_name_configuration {
    certificate_arn = var.cert_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  tags = var.tags
}

# ----------------------
# API Mappings
# ----------------------

# Map ECS service domain to the API
resource "aws_apigatewayv2_api_mapping" "ecs_mapping" {
  domain_name    = aws_apigatewayv2_domain_name.ecs_domain.id
  api_id         = aws_apigatewayv2_api.main_api.id
  stage          = aws_apigatewayv2_stage.main_stage.id
  api_mapping_key = "ecs-service"

}

# Map Auth service domain to the API
resource "aws_apigatewayv2_api_mapping" "auth_mapping" {
  domain_name    = aws_apigatewayv2_domain_name.auth_domain.id
  api_id         = aws_apigatewayv2_api.main_api.id
  stage          = aws_apigatewayv2_stage.main_stage.id
  api_mapping_key = "auth-service"
 
}


