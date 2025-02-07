# ----------------------
# VPC Link
# ----------------------
resource "aws_apigatewayv2_vpc_link" "my_vpc_link" {
  name = var.name
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
  cors_configuration {
    allow_origins = ["https://${var.app_domain}", "https://${var.auth_domain}", "https://${api.app_domain}"]
    allow_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST" ,"PUT"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_credentials = true
  }

  tags = var.tags
}

# ----------------------
# Integrations
# ----------------------

# Integration for ECS service
resource "aws_apigatewayv2_integration" "todo_service_integration" {
  api_id                = aws_apigatewayv2_api.main_api.id
  integration_type = "HTTP_PROXY"
  connection_type       = "VPC_LINK"
  connection_id           = aws_apigatewayv2_vpc_link.my_vpc_link.id
  integration_uri       = var.api_listener_arn
  integration_method    = "ANY"
  timeout_milliseconds  = 12000

  request_parameters = {
    "overwrite:path" = "$request.path" # Forwards the entire path
  }
  
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

resource "aws_apigatewayv2_route" "get_todo_by_id" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "GET /api/todos/{id}" # GET route for fetching a todo by ID
  target    = "integrations/${aws_apigatewayv2_integration.todo_service_integration.id}"
}

resource "aws_apigatewayv2_route" "update_todo" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "PUT /api/todos/{id}" # PUT route for updating a todo by ID
  target    = "integrations/${aws_apigatewayv2_integration.todo_service_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_todo" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "DELETE /api/todo/{id}" # DELETE route for deleting a todo by ID
  target    = "integrations/${aws_apigatewayv2_integration.todo_service_integration.id}"
}

resource "aws_apigatewayv2_route" "get_all_todos" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "GET /api/todos" # GET route for fetching all todos
  target    = "integrations/${aws_apigatewayv2_integration.todo_service_integration.id}"
}

resource "aws_apigatewayv2_route" "create_todo" {
  api_id    = aws_apigatewayv2_api.main_api.id
  route_key = "POST /api/todos" # POST route for creating a new todo
  target    = "integrations/${aws_apigatewayv2_integration.todo_service_integration.id}"
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
      responseLength  = "$context.responseLength",
      integrationError = "$context.integrationErrorMessage"
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
  api_mapping_key = "internal"

}

# Map Auth service domain to the API
resource "aws_apigatewayv2_api_mapping" "auth_mapping" {
  domain_name    = aws_apigatewayv2_domain_name.auth_domain.id
  api_id         = aws_apigatewayv2_api.main_api.id
  stage          = aws_apigatewayv2_stage.main_stage.id
  #api_mapping_key = "auth-service"
 
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





