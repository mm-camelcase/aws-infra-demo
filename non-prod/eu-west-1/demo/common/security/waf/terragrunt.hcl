include {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///aws-ss/wafv2/aws?version=3.0.0"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "gw-webacl")

  # need min 2 URIs for OR statementr below
  payload_size_whitelist_uris = [
    "/api/some/path/",
    "/api/some-other/path/"
  ]

  no_useragent_header_whitelist_uris = [
    "/api/some/path/",
    "/api/some-other/path/"
  ]

}

dependency "api-gateway" {
  config_path = "../../networking/api-gateway"
}

dependency "ipset" {
  config_path = "../waf-ipset/whitelist"
}

inputs = {
  enabled_web_acl_association = true
  resource_arn                = [dependency.api-gateway.outputs.arn]

  enabled_logging_configuration = false

  name           = local.name
  scope          = "REGIONAL"
  default_action = "allow"
  rule = [
    {
      name     = "Whitelist"
      priority = 1
      action   = "block"

      not_statement = {
        ip_set_reference_statement = {
          arn = dependency.ipset.outputs.aws_wafv2_ip_set_arn
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "BlockedNotWhitelisted"
        sampled_requests_enabled   = true
      }
    },
    {
      name            = "OverrideSizeRestrictionsForSpecificURIs"
      priority        = 2
      override_action = "none"
      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override = [
          {
            name          = "SizeRestrictions_BODY"
            action_to_use = "allow"
          }
        ]

        scope_down_statement = {
          or_statement = {
            statements = [
              for uri in local.payload_size_whitelist_uris : {
                byte_match_statement = {
                  search_string = uri
                  field_to_match = {
                    uri_path = {}
                  }
                  text_transformation = [
                    {
                      priority = 0
                      type     = "NONE"
                    }
                  ]
                  positional_constraint = "CONTAINS"
                }
              }
            ]
          }
        }


      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "OverrideSizeRestrictionsForSpecificURIs"
        sampled_requests_enabled   = true
      }
    },
    {
      name            = "OverrideUserAgentHeaderForSpecificURIs"
      priority        = 3
      override_action = "none"
      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override = [
          {
            name          = "NoUserAgent_HEADER"
            action_to_use = "allow"
          }
        ]

        scope_down_statement = {
          or_statement = {
            statements = [
              for uri in local.no_useragent_header_whitelist_uris : {
                byte_match_statement = {
                  search_string = uri
                  field_to_match = {
                    uri_path = {}
                  }
                  text_transformation = [
                    {
                      priority = 0
                      type     = "NONE"
                    }
                  ]
                  positional_constraint = "CONTAINS"
                }
              }
            ]
          }
        }


      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "OverrideUserAgentHeaderForSpecificURIs"
        sampled_requests_enabled   = true
      }
    },
    {
      # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html
      name            = "AWSManagedRules" # e.g. test : curl -H "User-Agent:" https://auth.camelcase.club
      priority        = 4
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
