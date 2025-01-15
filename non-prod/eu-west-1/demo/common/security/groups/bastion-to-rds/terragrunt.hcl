include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

dependency "vpc" {
  config_path = "../../../network/vpc"
}

dependency "bastion-sg" {
  config_path = "../bastion-sg"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "bastion-sg")
}

inputs = {

  name        = local.name
  description = "Security group for RDS access from EC2 Bastion instance"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # Define ingress rule for MSSQL core db
  ingress_with_source_security_group_id = [
    {
      from_port                = 1433,
      to_port                  = 1433,
      protocol                 = "tcp",
      description              = "Bastion",
      source_security_group_id = dependency.bastion-sg.outputs.security_group_id
    }
  ]

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


