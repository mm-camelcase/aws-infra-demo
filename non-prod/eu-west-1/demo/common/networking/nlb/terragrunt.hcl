include {
  path = find_in_parent_folders("root.hcl")
}

# using 9.2.0 because ist is compatible with ...
# downgrading from latest provider (5.31) because of issue --> Error: modifying ELBv2 Load Balancer InvalidConfigurationRequest: Key connection_logs.s3.enabled not valid
# may be just a localstack thing
terraform {
  source = "tfr:///terraform-aws-modules/alb/aws?version=9.13.0"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "nlb")
  whitelist  = ["10.2.6.0", "10.2.7.0"] // private vpc subnets of vpclink
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "bastion-sg" {
  config_path = "../../security/groups/bastion-sg"
}

inputs = {
  name = local.name

  load_balancer_type = "network"
  internal           = true

  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.private_subnets

  # For example only
  enable_deletion_protection = false

  idle_timeout = 600 # 10 mins (lower this for prod)

  security_group_ingress_rules = concat(
    [
      for ip in local.whitelist : {
        from_port   = 8080
        to_port     = 9000
        ip_protocol = "tcp"
        description = "vpclink subnets"
        cidr_ipv4   = "${ip}/24"
      }
    ],
    [
      {
        from_port                    = 8080
        to_port                      = 9000
        ip_protocol                  = "tcp"
        description                  = "bastion"
        referenced_security_group_id = dependency.bastion-sg.outputs.security_group_id
      }
    ]
  )


  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = dependency.vpc.outputs.vpc_cidr_block
    }
  }

  listeners = {

    tcp_user_service = {
      port     = 8080
      protocol = "TCP"

      forward = {
        target_group_key = "user_service"
      }
    }

    tcp_keycloak_service = {
      port     = 8090
      protocol = "TCP"

      forward = {
        target_group_key = "keycloak_service"
      }
    }
  }

  target_groups = {

    user_service = {
      protocol                          = "TCP"
      port                              = 8080
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2                  # Number of successes before marking as healthy
        interval            = 30                 # Reduce the interval for faster retries
        matcher             = "200"              # Expect HTTP 200 OK
        path                = "/actuator/health" # Health check endpoint
        port                = "8080"             # Target port for health checks
        protocol            = "HTTP"             # HTTP-based health check
        timeout             = 15                 # Increase timeout to 15 seconds for slower responses
        unhealthy_threshold = 5                  # Allow up to 5 failures during startup
      }

      create_attachment = false
    }

    keycloak_service = {
      protocol                          = "TCP"
      port                              = 8090
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2         # Number of successes before marking as healthy
        interval            = 30        # Reduce the interval for faster retries
        matcher             = "200"     # Expect HTTP 200 OK
        path                = "/health" # Health check endpoint
        port                = "9000"    # Target port for health checks
        protocol            = "HTTP"    # HTTP-based health check
        timeout             = 15        # Increase timeout to 15 seconds for slower responses
        unhealthy_threshold = 5         # Allow up to 5 failures during startup
      }

      create_attachment = false
    }

  }

}