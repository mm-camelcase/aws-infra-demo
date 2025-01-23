include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-apigateway-v2?ref=v5.1.2"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "nlb" {
  config_path = "../nlb"
}

dependency "gateway-sg" {
  config_path = "../../security/groups/gateway-sg"
}

dependency "cert" {
  config_path = "../../security/cert"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "gateway")

  api_domain = "api.camelcase.club"
}

inputs = {
  # API
  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  description = "HTTP API Gateway with VPC links"
  name        = local.name

  # Custom Domain
  create_domain_name = true

  domain_name = local.api_domain

  #domain_name_certificate_arn = dependency.cert.outputs.certificate_arn

  domain_name_configuration = {
    certificate_arn = dependency.cert.outputs.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
    #ownership_verification_certificate_arn = var.domain_name_ownership_verification_certificate_arn
  }


  # VPC Link
  vpc_links = {
    my-vpc = {
      name               = local.name
      security_group_ids = [dependency.gateway-sg.outputs.security_group_id]
      subnet_ids         = dependency.vpc.outputs.private_subnets
    }
  }

  # Routes & Integration(s)
  routes = {
    # Default route to ECS service via NLB
    "ANY /ecs-service" = {
      integration = {
        connection_type      = "VPC_LINK"
        uri                  = dependency.nlb.outputs.listeners["tcp_user_service"].arn # NLB Listener ARN
        type                 = "HTTP_PROXY"
        method               = "ANY"
        timeout_milliseconds = 12000
        vpc_link_key         = "my-vpc"
      }
    }

    # Example: A catch-all default route (optional)
    "$default" = {
      integration = {
        connection_type      = "VPC_LINK"
        uri                  = dependency.nlb.outputs.listeners["tcp_user_service"].arn # Default to ECS NLB
        type                 = "HTTP_PROXY"
        method               = "ANY"
        timeout_milliseconds = 12000
        vpc_link_key         = "my-vpc"
      }
    }
  }
}



