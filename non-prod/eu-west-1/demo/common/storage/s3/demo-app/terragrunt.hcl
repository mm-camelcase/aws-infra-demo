include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v4.1.2"
}

locals {
  acc_config  = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  bucket_name = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "demo-app")
}

dependency "cloudfront" {
  config_path = "../../networking/cloudfront/demo-app"
}

inputs = {
  bucket        = local.bucket_name
  force_destroy = true
  attach_policy = true

  # S3 Bucket Ownership Controls
  object_ownership = "BucketOwnerEnforced"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${local.bucket_name}/*",
          "arn:aws:s3:::${local.bucket_name}"
        ]
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = dependency.cloudfront.outputs.cloudfront_distribution_arn
          }
        }
      }
    ]
  })

}
