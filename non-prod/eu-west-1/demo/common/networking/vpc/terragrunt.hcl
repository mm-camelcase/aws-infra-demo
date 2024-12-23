include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.4.0"
}

dependency az {
  config_path = "../azs"

  mock_outputs = {
    available_azs = ["us-east-1a", "us-east-1b"]
  }
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s", local.env_config.locals.env, "vpc")
  vpc_cidr   = "10.2.0.0/16"

  # vpc_cidr   = "10.2.0.0/16" # demo-vpc
  # vpc_cidr   = "10.3.0.0/16" # staging-vpc
  # vpc_cidr   = "10.1.0.0/16" # prod-vpc



}

inputs = {
  name               = local.name
  cidr               = local.vpc_cidr
  azs                = dependency.az.outputs.available_azs
  enable_nat_gateway = true
  single_nat_gateway = true
  // todo: 1 az is fine
  #private_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k + 6)] // new vpc
  #public_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  public_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k)] // new vpc
  #database_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]
  database_subnets = [for k, v in dependency.az.outputs.available_azs : cidrsubnet(local.vpc_cidr, 8, k + 12)] // new vpc

  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest#public-access-to-rds-instances
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}