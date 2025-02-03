include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

dependency "security-group" {
  config_path = "../../groups/ecs-to-rds"
}

dependency "ecs-services-sg" {
  config_path = "../../groups/ecs-services"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "ecs-to-rds")
}

inputs = {

  create_sg         = false
  security_group_id = dependency.security-group.outputs.security_group_id
  ingress_with_source_security_group_id = [
    {
      description              = "db port from ecs services"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = dependency.ecs-services-sg.outputs.security_group_id
    },
  ]

}


