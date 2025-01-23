output "certificate_arn" {
  value = data.aws_acm_certificate.amazon_issued.arn
}