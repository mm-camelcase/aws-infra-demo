include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

dependency "vpc" {
  config_path = "../../../network/vpc"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "ecs-to-rds")
}

inputs = {

  name        = local.name
  description = "Security group for RDS alowing access from the ECS tasks"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # Allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      description = "All outbound",
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Inbounds rules will be added after ECS resources are created

}


