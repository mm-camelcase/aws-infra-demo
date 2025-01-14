include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ecs//modules/service?ref=v5.12.0"
}


locals {
  name = "user-service"

  acc_config    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_config = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  common_config = read_terragrunt_config(find_in_parent_folders("common/core-params.hcl"))

  repo_base       = local.common_config.locals.repo_base
  service_name    = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, local.name)
  image           = format("%s/%s", local.common_config.locals.repo_base, local.name)
  image_version   = read_terragrunt_config(find_in_parent_folders("service-versions.hcl")).locals.services[local.name]
  param_base_path = local.common_config.locals.param_base_path
  acc_kms_keys    = local.common_config.locals.acc_kms_keys

  env            = local.env_config.locals.env
  spring_profile = local.env_config.locals.spring_profile
  region         = local.region_config.locals.aws_region
  container_port = 8080
  host_port      = 8080


}

dependency "ecs-cluster" {
  config_path = "../../ecs-cluster"
}

dependency "service-discovery" {
  config_path = "../../service-discovery/cloud-map"
}

# dependency "alb" {
#   config_path = "../../../network/alb"
# }

dependency "vpc" {
  config_path = "../../../common/networking/vpc"
}

# dependency "param-store" {
#   config_path = "../../../storage/parameter-store"
# }

# dependency "jump-box" {
#   config_path = "../../../network/bastion"
# }

# dependency "jump-box-sg" {
#   config_path = "../../../security/groups/bastion-sg"
# }

dependency "ecs-services-sg" {
  config_path = "../../../common/security/groups/ecs-services"
}

inputs = {
  name        = local.service_name
  cluster_arn = dependency.ecs-cluster.outputs.arn

  #ephemeral = true

  cpu    = 1024
  memory = 2048

  # Enables ECS Exec (if true requires readonly_root_filesystem=false and IAM)
  enable_execute_command = true
  pid_mode               = "task" # https://docs.datadoghq.com/integrations/ecs_fargate/?tab=webui#process-collection

  desired_count      = 1
  enable_autoscaling = false

  container_definitions = {

    (local.name) = {
      cpu                = 0    # Allows it to burst up to the task limit if available
      memory             = 1664 # Hard limit
      memory_reservation = 256  # Soft limit
      essential          = true
      image              = format("%s:%s", local.image, local.image_version)
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

      # log_configuration = {
      #   logDriver = "awsfirelens"
      #   options = {
      #     Name           = "datadog"
      #     Host           = "http-intake.logs.datadoghq.eu"
      #     dd_service     = local.name
      #     dd_source      = "java"
      #     dd_message_key = "@message"
      #     dd_tags        = "env:${local.env},service:${local.name},version:${local.image_version}"
      #     TLS            = "on"
      #     provider       = "ecs"
      #   }
      #   secretOptions : [{
      #     name : "apikey"
      #     valueFrom : format("${local.param_base_path}/common/datadog/dd-api-key")
      #   }]
      # }

      linux_parameters = {
        capabilities = {
          # best practice security measure (restricts the container from using raw and packet sockets)
          drop = [
            "NET_RAW"
          ]
        }
      }

      environment = [{
        name  = "SPRING_PROFILES_ACTIVE"
        value = local.spring_profile
        },
        # {
        #   name  = "FORCE_REDEPLOY"
        #   value = "${timestamp()}"
        # },
        {
          name  = "JAVA_OPTS"
          value = "-Xmx1600m"
        },
        {
          name  = "JAVA_TOOL_OPTIONS"
          value = ""
        },
        # {
        #   name  = "RABBIT_HOST"
        #   value = dependency.service-discovery.outputs.rabbit_mq_service_discovery_url
        # },
        # {
        #   name  = "RABBIT_PORT"
        #   value = 5672
        # },
        # {
        #   name  = "MONGO_HOST"
        #   value = dependency.service-discovery.outputs.mongo_db_service_discovery_url
        # },
        # {
        #   name  = "MONGO_PORT"
        #   value = 27017
        # },
        # {
        #   name  = "TRADE_SERVICE_URL"
        #   value = format("%s%s:%s", "http://", dependency.service-discovery.outputs.trade_service_discovery_url, 8072)
        # },
        # {
        #   name  = "CORE_SERVICES_URL"
        #   value = format("%s%s:%s", "http://", dependency.service-discovery.outputs.core_service_discovery_url, 8071)
        # },
        # {
        #   name  = "CHECKLIST_URL"
        #   value = format("%s%s:%s", "http://", dependency.service-discovery.outputs.checklist_api_service_discovery_url, 3003)
        # },
        # {
        #   name  = "HOST_NAME"
        #   value = "ecs-${local.env}-${local.acc_config.locals.resource_prefix}"
        # },
        # {
        #   name  = "DD_ENV"
        #   value = local.env
        # },
        # {
        #   name  = "DD_SERVICE"
        #   value = local.name
        # },
        # {
        #   name  = "DD_VERSION"
        #   value = local.image_version
        # }
      ]

      # secrets = [
      #   {
      #     name      = "SQLDB_URL"
      #     valueFrom = format("%s/%s", local.param_base_path, "common/db/core-mssql/sql-jdbc-url")
      #   },
      #   {
      #     name      = "SQL_USER"
      #     valueFrom = format("%s/%s", local.param_base_path, "common/db/core-mssql/user")
      #   },
      #   {
      #     name      = "SQL_PASS"
      #     valueFrom = format("%s/%s", local.param_base_path, "common/db/core-mssql/password")
      #   }
      # ]

      mount_points = [
        {
          sourceVolume  = "tmp-dir"
          containerPath = "/tmp"
        }
      ]

      # 170 seconds 
      health_check = {
        command     = ["curl", "-f", "http://localhost:${local.container_port}/user/actuator/health"]
        interval    = 30,
        timeout     = 15,
        retries     = 3
        startPeriod = 170
      }
    }
    #datadog-agent = local.common_config.locals.sidecars.datadog_container
    #fluent-bit = local.common_config.locals.sidecars.fluentbit_container
  }

  volume = {
    "tmp-dir" = {}
  }

  service_registries = {
    registry_arn = dependency.service-discovery.outputs.user_service_discovery_arn
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




