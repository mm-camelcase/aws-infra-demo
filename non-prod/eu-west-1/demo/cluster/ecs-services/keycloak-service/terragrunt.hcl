include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecs//modules/service?ref=v5.12.0"
}


locals {
  name = "keycloak-service"

  acc_config    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_config = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  common_config = read_terragrunt_config(find_in_parent_folders("common/core-params.hcl"))

  repo_base       = local.common_config.locals.repo_base
  service_name    = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, local.name)
  param_base_path = local.common_config.locals.param_base_path
  acc_kms_keys    = local.common_config.locals.acc_kms_keys

  env            = local.env_config.locals.env
  spring_profile = local.env_config.locals.spring_profile
  region         = local.region_config.locals.aws_region
  container_port = 8090
  host_port      = 8090
  admin_port     = 9000
  auth_domain    = local.env_config.locals.auth_domain

}

dependency "ecs-cluster" {
  config_path = "../../ecs-cluster"
}

dependency "service-discovery" {
  config_path = "../../service-discovery/cloud-map"
}

dependency "nlb" {
  config_path = "../../../common/networking/nlb"
}

dependency "vpc" {
  config_path = "../../../common/networking/vpc"
}

dependency "bastion-sg" {
  config_path = "../../../common/security/groups/bastion-sg"
}

dependency "ecs-services-sg" {
  config_path = "../../../common/security/groups/ecs-services"
}

inputs = {
  name        = local.service_name
  cluster_arn = dependency.ecs-cluster.outputs.arn

  #ephemeral = true

  cpu    = 512
  memory = 1024

  # Enables ECS Exec (if true requires readonly_root_filesystem=false and IAM)
  enable_execute_command = true
  pid_mode               = "task" # https://docs.datadoghq.com/integrations/ecs_fargate/?tab=webui#process-collection

  desired_count      = 1
  enable_autoscaling = false

  container_definitions = {

    (local.name) = {
      cpu                = 0    # Allows it to burst up to the task limit if available
      memory             = 1024 # Hard limit
      memory_reservation = 256  # Soft limit
      essential          = true
      image              = "quay.io/keycloak/keycloak:latest"
      port_mappings = [
        {
          name          = local.name
          containerPort = local.container_port
          hostPort      = local.host_port
          protocol      = "tcp"
        }
      ]

      # minimize the risk of malicious modifications (java requires a /tmp directory to be present, see mount_points below), 
      # must be false for ECS Exec
      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true

      linux_parameters = {
        capabilities = {
          # best practice security measure (restricts the container from using raw and packet sockets)
          drop = [
            "NET_RAW"
          ]
        }
      }

      environment = [
        {
          name  = "KC_HEALTH_ENABLED"
          value = "true"
        },
        {
          name  = "KC_HTTP_PORT"
          value = "${local.container_port}"
        },
        {
          name  = "KC_PROXY_HEADERS"
          value = "forwarded"
        },
        {
          name  = "KC_FEATURES"
          value = "hostname:v2"
        },
        {
          name  = "KC_HOSTNAME"
          value = "https://${local.auth_domain}"
        },
        {
          name  = "KC_DB_URL_PORT"
          value = "5432"
        },
        {
          name  = "KC_DB_DRIVER"
          value = "org.postgresql.Driver"
        },
        {
          name  = "KC_DB"
          value = "postgres"
        },
        {
          name  = "KC_HTTP_ENABLED"
          value = "true"
        }
      ]

      #command = ["start-dev"] # dev mode, ephemeral container local in mem db

      command = ["start"]

      secrets = [
        {
          name      = "KC_DB_URL_HOST"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/sql-jdbc-url")
        },
        {
          name      = "KC_DB_URL_DATABASE"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/keycloak-db-name")
        },
        {
          name      = "KC_BOOTSTRAP_ADMIN_USERNAME"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/keycloak-db-master-username")
        },
        {
          name      = "KC_BOOTSTRAP_ADMIN_PASSWORD"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/keycloak-db-master-password")
        },
        {
          name      = "KC_DB_USERNAME"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/keycloak-db-username")
        },
        {
          name      = "KC_DB_PASSWORD"
          valueFrom = format("%s/%s", local.param_base_path, "common/rds/keycloak-db-password")
        }
      ]


      mount_points = [
        {
          sourceVolume  = "tmp-dir"
          containerPath = "/tmp"
        }
      ]

      # using nlb health check
      # health_check = {
      #   command     = ["curl", "-f", "http://localhost:${local.container_port}/actuator/health"]
      #   interval    = 30,
      #   timeout     = 15,
      #   retries     = 5
      #   startPeriod = 170
      # }
    }

  }

  volume = {
    "tmp-dir" = {}
  }

  load_balancer = {
    service = {
      target_group_arn = dependency.nlb.outputs.target_groups["keycloak_service"].arn
      container_name   = local.name
      container_port   = local.container_port
    }
  }

  subnet_ids         = dependency.vpc.outputs.private_subnets
  security_group_ids = [dependency.ecs-services-sg.outputs.security_group_id]
  security_group_rules = {
    ingress_ecs_services = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = dependency.ecs-services-sg.outputs.security_group_id
    }
    ingress_bastion_services = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.admin_port
      protocol                 = "tcp"
      description              = "Bastion"
      source_security_group_id = dependency.bastion-sg.outputs.security_group_id
    }
    ingress_nlb = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.admin_port
      protocol                 = "tcp"
      description              = "nlb"
      source_security_group_id = dependency.nlb.outputs.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  task_exec_iam_statements = {
    # Required ECR perms
    ecr_access = {
      effect = "Allow"
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
      resources = ["*"]
    }

    kms_decrypy = {
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]
      resources = [local.acc_kms_keys]
    }

    # Required CloudWatch Logs perms
    cloudwatch_logs = {
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ]
      resources = ["*"]
    }
  }


}




