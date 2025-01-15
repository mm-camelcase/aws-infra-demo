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
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "ecs-services")
}

inputs = {

  name        = local.name
  description = "Reference SG that will be added to all ECS services, for the purpose of referencing all services in other security group rules"
  vpc_id      = dependency.vpc.outputs.vpc_id

}


