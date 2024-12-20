# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name    = "cc-infra"
  aws_account_id  = "966412459053"
  resource_prefix = "cc-infra"
}