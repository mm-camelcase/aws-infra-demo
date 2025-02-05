include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///aws-ss/wafv2/aws?version=3.0.0"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "demo-app-webacl")
}


inputs = {
  resource_arn = []

  enabled_logging_configuration = false

  name  = local.name
  scope = "CLOUDFRONT"

  default_action = "allow"
  rule = [
    # {
    #   name     = "Whitelist"
    #   priority = 1
    #   action   = "block"

    #   not_statement = {
    #     ip_set_reference_statement = {
    #       arn = dependency.ipset.outputs.aws_wafv2_ip_set_arn
    #     }
    #   }

    #   visibility_config = {
    #     cloudwatch_metrics_enabled = true
    #     metric_name                = "BlockedNotWhitelisted"
    #     sampled_requests_enabled   = true
    #   }
    # },
    {
      # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html
      name            = "AWSManagedRules" # e.g. test : curl -H "User-Agent:" https://auth.camelcase.club
      priority        = 2
      override_action = "none"
      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowedAWSManagedRules"
        sampled_requests_enabled   = true
      }
    }
  ]
  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "ALBWebACL"
    sampled_requests_enabled   = true
  }

}
