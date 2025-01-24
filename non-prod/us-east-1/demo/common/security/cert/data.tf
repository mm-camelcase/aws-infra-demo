data "aws_acm_certificate" "amazon_issued" {
  domain      = "*.camelcase.club"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}