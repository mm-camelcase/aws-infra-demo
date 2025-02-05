include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///aws-ss/wafv2/aws//modules/ip-set?version=3.0.0"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "alb-webacl-ipset")

  whitelist_ips = read_terragrunt_config(find_in_parent_folders("whitelist.hcl"))
}

dependency "vpc" {
  config_path = "../../networking/vpc"
}


inputs = {
  name               = local.name
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  # adding the NAT public IP to the whitelist 
  addresses = concat(
    [for entry in local.whitelist_ips.locals.whitelist : "${entry.ip}/32"],
    ["${dependency.vpc.outputs.nat_public_ips[0]}/32"]
  )
}
