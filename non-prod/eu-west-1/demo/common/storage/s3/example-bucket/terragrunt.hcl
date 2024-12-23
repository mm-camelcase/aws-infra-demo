include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v4.2.2"
}

locals {
  # example showing how to find and read a config file from a parent folder
  acc_config  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  bucket_name = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "test-bucket-001")
}

inputs = {
  bucket = local.bucket_name
}
