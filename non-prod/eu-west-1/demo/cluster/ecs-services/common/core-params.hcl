# sidecars.hcl
locals {
  acc_config    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_config = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  repo_base       = "${local.acc_config.locals.aws_account_id}.dkr.ecr.${local.region_config.locals.aws_region}.amazonaws.com"
  param_base_path = "arn:aws:ssm:${local.region_config.locals.aws_region}:${local.acc_config.locals.aws_account_id}:parameter/${local.env_config.locals.spring_profile}"
  acc_kms_keys    = "arn:aws:kms:${local.region_config.locals.aws_region}:${local.acc_config.locals.aws_account_id}:key/*"

  sidecars = {
    # datadog_container = {
    #   name                      = "datadog-agent"
    #   image                     = "public.ecr.aws/datadog/agent:7.55.1"
    #   cpu                       = 128 # 0.125 vCPU
    #   memory                    = 256 # 256 MiB (got OOM error with 128 MiB)
    #   essential                 = false
    #   readonly_root_filesystem  = false
    #   enable_cloudwatch_logging = true
    #   #memory_reservation        = 100
    #   environment = [
    #     { name = "DD_SITE", value = "datadoghq.eu" },
    #     { name = "ECS_FARGATE", value = "true" },
    #     { name = "DD_APM_ENABLED", value = "true" },
    #     { name = "DD_APM_ENV", value = local.env_config.locals.env },
    #     { name = "DD_PROCESS_AGENT_ENABLED", value = "true" },
    #     { name = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC", value = "true" }
    #   ]
    #   secrets = [
    #     #{ name = "DD_API_KEY", valueFrom = format("%s/%s", local.param_base_path, "common/datadog/dd-api-key") }
    #     { name = "DD_API_KEY", valueFrom = format("%s/%s", "arn:aws:ssm:${local.region_config.locals.aws_region}:${local.acc_config.locals.aws_account_id}:parameter/${local.env_config.locals.spring_profile}", "common/datadog/dd-api-key") }
    #   ]
    # }

    fluentbit_container = {
      name      = "log-router"
      image     = "amazon/aws-for-fluent-bit:stable"
      cpu       = 128 # 0.125 vCPU
      memory    = 128 # 128 MiB
      essential = false
      firelens_configuration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
          config-file-type        = "file"
          config-file-value       = "/fluent-bit/configs/parse-json.conf"
        }
      }
      #memory_reservation = 50
    }
  }

}

# locals {
#   sidecars = [
#     local.datadog_container,
#     local.fluentbit_container
#   ]
# }

# inputs = {
#   sidecars = local.sidecars
# }
