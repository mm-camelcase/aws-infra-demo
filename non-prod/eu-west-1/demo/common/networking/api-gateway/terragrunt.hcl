include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "./"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "nlb" {
  config_path = "../nlb"
}

dependency "gateway-sg" {
  config_path = "../../security/groups/gateway-sg"
}

dependency "cert" {
  config_path = "../../security/cert"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "gateway") // same as ecs-service
}

inputs = {
  name = local.name
  //vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids        = dependency.vpc.outputs.private_subnets
  api_listener_arn  = dependency.nlb.outputs.listeners["tcp_user_service"].arn
  auth_listener_arn = dependency.nlb.outputs.listeners["tcp_keycloak_service"].arn
  cert_arn          = dependency.cert.outputs.certificate_arn
  gateway-sg-id     = dependency.gateway-sg.outputs.security_group_id
}