data "aws_availability_zones" "available" {
  state = "available" # or use "optimized" to get zones recommended for EC2 usage
}
