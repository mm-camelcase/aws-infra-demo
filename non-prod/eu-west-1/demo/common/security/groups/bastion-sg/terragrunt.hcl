include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

dependency "vpc" {
  config_path = "../../../networking/vpc"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "bastion-sg")
}

inputs = {

  name        = local.name
  description = "Security group for EC2 Bastion instance"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # Define ingress rule for PostgreSQL
  # ingress_with_cidr_blocks = [
  #   {
  #     from_port   = 22,
  #     to_port     = 22,
  #     protocol    = "tcp",
  #     description = "Bastion",
  #     cidr_blocks = "5.179.68.90/32" # Adjust this to a more restrictive CIDR or use `var.ecs_tasks_sg_id` for ECS tasks
  #   }
  # ]

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
}


