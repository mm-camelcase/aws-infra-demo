include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-rds?ref=v6.10.0"
}

dependency "vpc" {
  config_path = "../../../networking/vpc"
}



dependency "ecs-sg" {
  config_path = "../../../security/groups/ecs-to-rds"
}

dependency "bastion-to-rds-sg" {
  config_path = "../../../security/groups/bastion-to-rds"
}


locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "db")
}

inputs = {
  identifier = local.name

  engine               = "postgres"
  engine_version       = "16.3"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t3.micro"

  allocated_storage     = 5
  max_allocated_storage = 20
  publicly_accessible   = false

  # Encryption at rest is not available for DB instances running SQL Server Express Edition
  storage_encrypted = false

  #username = dependency.param-store.outputs.parameters["/${local.env_config.locals.spring_profile}/common/db/core-mssql/user"]
  username = "mm123"
  port     = 5432

  manage_master_user_password = true

  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group_name
  vpc_security_group_ids = [dependency.bastion-to-rds-sg.outputs.security_group_id, dependency.ecs-sg.outputs.security_group_id]

  maintenance_window              = "Sat:00:00-Sat:03:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  #backup_retention_period = 1
  skip_final_snapshot = true
  deletion_protection = false

}


# see https://github.com/terraform-aws-modules/terraform-aws-rds/blob/v6.3.1/examples/complete-postgres/main.tf