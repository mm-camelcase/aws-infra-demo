# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "./"
}

# wildcard_domain

locals {
  env_config      = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  wildcard_domain = local.env_config.locals.wildcard_domain
}

inputs = {
  wildcard_domain = local.wildcard_domain
}

