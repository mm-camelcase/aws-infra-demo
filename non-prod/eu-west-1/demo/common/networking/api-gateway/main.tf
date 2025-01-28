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
resource "aws_apigatewayv2_integration" "user_service_integration" {
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
# resource "aws_apigatewayv2_route" "ecs_route" {
#   api_id      = aws_apigatewayv2_api.main_api.id
#   route_key   = "ANY /"
#   target      = "integrations/${aws_apigatewayv2_integration.ecs_integration.id}"
  
# }

resource "aws_apigatewayv2_route" "get_user_by_id" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "GET /api/users/{id}" # GET route for fetching a user by ID
  target    = "integrations/${aws_apigatewayv2_integration.user_service_integration.id}"
}

resource "aws_apigatewayv2_route" "update_user" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "PUT /api/users/{id}" # PUT route for updating a user by ID
  target    = "integrations/${aws_apigatewayv2_integration.user_service_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_user" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "DELETE /api/users/{id}" # DELETE route for deleting a user by ID
  target    = "integrations/${aws_apigatewayv2_integration.user_service_integration.id}"
}

resource "aws_apigatewayv2_route" "get_all_users" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "GET /api/users" # GET route for fetching all users
  target    = "integrations/${aws_apigatewayv2_integration.user_service_integration.id}"
}

resource "aws_apigatewayv2_route" "create_user" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "POST /api/users" # POST route for creating a new user
  target    = "integrations/${aws_apigatewayv2_integration.user_service_integration.id}"
}

# Route for Auth service
resource "aws_apigatewayv2_route" "auth_route" {
  api_id      = aws_apigatewayv2_api.main_api.id
  route_key   = "ANY /{proxy+}"
  target      = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
  
}

# ----------------------
# Stages
# ----------------------

# Create a default stage for the API
//resource "aws_apigatewayv2_stage" "main_stage" {
//  api_id      = aws_apigatewayv2_api.main_api.id
//  name        = "$default"
//  auto_deploy = true
//  tags = var.tags
//}

# API Gateway Stage with Logging
resource "aws_apigatewayv2_stage" "main_stage" {
  api_id      = aws_apigatewayv2_api.main_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      routeKey        = "$context.routeKey",
      status          = "$context.status",
      protocol        = "$context.protocol",
      responseLength  = "$context.responseLength"
    })
  }

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

# ----------------------
# Logging
# ----------------------

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/access-logs"
  retention_in_days = 7
}

# IAM Role and Policy for Logging
resource "aws_iam_role" "api_gateway_logging_role" {
  name = "api-gateway-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_logging_policy" {
  name = "api-gateway-logging-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "${aws_cloudwatch_log_group.api_gateway_logs.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_logging_attachment" {
  role       = aws_iam_role.api_gateway_logging_role.name
  policy_arn = aws_iam_policy.api_gateway_logging_policy.arn
}





