variable "ec2_instance_id" {
  type = string
  description = "EC2 instance id to attach EIP to"
}

resource "aws_eip" "bastion_eip" {
  instance = var.ec2_instance_id
  vpc      = true
}