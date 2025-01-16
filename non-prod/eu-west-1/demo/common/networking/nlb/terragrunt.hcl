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
  //dotnet_platform_outbound_ips = ["104.45.14.249", "104.45.14.250", "104.45.14.251", "104.45.14.252", "104.45.14.253", "13.69.68.36"] # Outbound IPs for the dotnet platform
  //core_db_ip                   = "10.3.12.32"
  whitelist = ["54.72.131.136"]
}

dependency "vpc" {
  config_path = "../vpc"
}

# dependency "cert" {
#   config_path = "../../security/certs/core-ssl"
# }

# dependency "param-store" {
#   config_path = "../../storage/parameter-store"
# }


inputs = {
  name = local.name

  load_balancer_type = "network"

  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.public_subnets

  # For example only
  enable_deletion_protection = false

  idle_timeout = 600 # 10 mins (lower this for prod)

  security_group_ingress_rules = {
    # handle 8080
    for ip in local.whitelist : ip => {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = "${ip}/32"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = dependency.vpc.outputs.vpc_cidr_block
    }
  }

  listeners = {
    # tcp_rabbitmq = {
    #   port     = 5672
    #   protocol = "TCP"

    #   forward = {
    #     target_group_key = "rabbitmq_service"
    #   }
    # }
    # tcp_mssql = {
    #   port     = 1433
    #   protocol = "TCP"

    #   forward = {
    #     target_group_key = "rds_mssql"
    #   }
    # }
    http_user_service = {
      port     = 1433
      protocol = "HTTP"

      forward = {
        target_group_key = "user_service"
      }
    }
  }

  target_groups = {
    # rabbitmq_service = {
    #   protocol                          = "TCP"
    #   port                              = 5672
    #   target_type                       = "ip"
    #   deregistration_delay              = 5
    #   load_balancing_cross_zone_enabled = true

    #   health_check = {
    #     enabled             = true
    #     healthy_threshold   = 2
    #     interval            = 70
    #     matcher             = "200"
    #     path                = "/"
    #     port                = "15672"
    #     protocol            = "HTTP"
    #     timeout             = 10
    #     unhealthy_threshold = 3
    #   }

    #   create_attachment = false
    # }

    # rds_mssql = {
    #   protocol                          = "TCP"
    #   port                              = 1433
    #   target_type                       = "ip"
    #   target_id                         = local.core_db_ip
    #   deregistration_delay              = 5
    #   load_balancing_cross_zone_enabled = true

    #   health_check = {
    #     enabled             = true
    #     healthy_threshold   = 2
    #     interval            = 30
    #     port                = "1433"
    #     protocol            = "TCP"
    #     timeout             = 5
    #     unhealthy_threshold = 3
    #   }

    #   create_attachment = true

    # }

    user_service = {
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 70
        matcher             = "200"
        path                = "/"
        port                = "8080"
        protocol            = "HTTP"
        timeout             = 10
        unhealthy_threshold = 3
      }

      create_attachment = false
    }

  }

}