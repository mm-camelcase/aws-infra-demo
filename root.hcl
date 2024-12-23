# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# 

locals {

  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))


  common_tags = {
    application     = "cc-demo-app"
    functional_area = "cc-demo-infra"
    owner_email     = "mark@camelcase.email"
    support_email   = "mark@camelcase.email"
  }

  # Merge common tags with the environment tag
  merged_tags = merge(
    local.common_tags,
    { "env" = local.environment_vars.locals.env }
  )

  # Extract the variables we need for easy access below
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.aws_region
  env          = local.environment_vars.locals.env
}

# ---------------------------------------------------------------------------------------------------------------------
# Need to overide root provider and remote_state as localstack requiresextra config parameters
# ---------------------------------------------------------------------------------------------------------------------

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  
    region                      = "${local.aws_region}"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    s3_use_path_style         = true
    

    %{if local.env == "local"}
    access_key                  = "fake"
    secret_key                  = "fake"

    endpoints {
        apigateway           = "http://localhost:4566"
        elbv2                = "http://localhost:4566"
        cloudformation       = "http://localhost:4566"
        cloudwatch           = "http://localhost:4566"
        cloudwatchevents     = "http://localhost:4566"
        cloudwatchlogs       = "http://localhost:4566"
        dynamodb             = "http://localhost:4566"
        ec2                  = "http://localhost:4566"
        ecs                  = "http://localhost:4566"
        es                   = "http://localhost:4566"
        firehose             = "http://localhost:4566"
        iam                  = "http://localhost:4566"
        kinesis              = "http://localhost:4566"
        kms                  = "http://localhost:4566"
        lambda               = "http://localhost:4566"
        route53              = "http://localhost:4566"
        redshift             = "http://localhost:4566"
        s3                   = "http://localhost:4566"
        secretsmanager       = "http://localhost:4566"
        ses                  = "http://localhost:4566"
        sns                  = "http://localhost:4566"
        sqs                  = "http://localhost:4566"
        ssm                  = "http://localhost:4566"
        stepfunctions        = "http://localhost:4566"
        sts                  = "http://localhost:4566"
        swf                  = "http://localhost:4566"
        #timestreamwrite      = "http://localhost:4566"
        #timestreamquery      = "http://localhost:4566"
    }
    %{endif}


}
EOF
}


# downgrading from latest provider (5.31) because of issue --> Error: modifying ELBv2 Load Balancer InvalidConfigurationRequest: Key connection_logs.s3.enabled not valid
# may be just a localstack thing
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      required_providers {
        aws = {
          source = "hashicorp/aws"
          version = ">= 5.81"
        }
      }
    

    }
EOF
}


# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    access_key = local.env == "local" ? "fake" : null
    secret_key = local.env == "local" ? "fake" : null
    bucket     = "${local.env}-${local.account_name}${local.aws_region != "eu-west-1" ? "-${local.aws_region}" : ""}-terraform-state"
    #endpoint                    = local.env == "local" ? "http://localhost.localstack.cloud:4566" : null
    endpoint                    = local.env == "local" ? "http://localhost:4566" : null
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_region_validation      = true
    force_path_style            = true
    #skip_metadata_api_check     = true
    #session_token               = false
    key               = "${path_relative_to_include()}/terraform.tfstate"
    region            = local.aws_region
    encrypt           = true
    dynamodb_table    = "${local.account_name}-${local.env}-lock-table"
    dynamodb_endpoint = local.env == "local" ? "http://localhost:4566" : null
  }

}


inputs = {
  tags = local.merged_tags
}
