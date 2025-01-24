include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-cloudfront?ref=v3.2.0"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  comment   = "Demo App"
  subdomain = "app.camelcase.club"

  # domain name of bucket that this CloudFront distribution will serve (will generate here to avoid circular dependency)
  bucket_domain_name = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "demo-app.s3.amazonaws.com")
}

# dependency "waf" {
#   config_path = "../../../../../us-east-1/stage/security/waf/sign-up-form"
# }

dependency "cert" {
  config_path = "../../../../../../us-east-1/stage/common/security/cert"
}

inputs = {
  comment = local.comment
  enabled = true
  aliases = [local.subdomain]
  //web_acl_id          = dependency.waf.outputs.aws_wafv2_arn
  default_root_object = "index.html"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3_oac = { # with origin access control settings (recommended)
      domain_name           = local.bucket_domain_name
      origin_access_control = "s3_oac" # key in `origin_access_control`
    }
  }

  default_cache_behavior = {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3_oac"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values = {
      query_string = false
      cookies = {
        forward = "none"
      }
    }

  }

  # Add custom error responses to redirect to index.html for SPA routing
  custom_error_response = [{
    error_code            = 403
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
    }, {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 0
  }]


  viewer_certificate = {
    acm_certificate_arn      = dependency.cert.outputs.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}
