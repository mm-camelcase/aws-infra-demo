# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  env            = "demo"
  spring_profile = "demo"

  auth_domain     = "auth.camelcase.club"
  app_domain      = "app.camelcase.club"
  api_domain      = "api.camelcase.club"
  wildcard_domain = "*.camelcase.club"
}