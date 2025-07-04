include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance?ref=v5.6.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "bastion-sg" {
  config_path = "../../security/groups/bastion-sg"
}

locals {
  acc_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  name       = format("%s-%s-%s", local.env_config.locals.env, local.acc_config.locals.resource_prefix, "jump-box")
}

inputs = {
  name                        = local.name
  instance_type               = "t3a.micro"
  key_name                    = "bastion-key-pair"
  monitoring                  = true
  vpc_security_group_ids      = [dependency.bastion-sg.outputs.security_group_id]
  subnet_id                   = dependency.vpc.outputs.public_subnets[0]
  associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_description        = "Session Manager role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonSSMFullAccess          = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  }
  cpu_core_count              = null
  cpu_threads_per_core        = null
  spot_block_duration_minutes = null
}



# ran this manually 
# aws ec2 create-key-pair --key-name bastion-key-pair --query 'KeyMaterial' --output text > ~/.ssh/bastion-key-pair.pem

# ssh -i .ssh/bastion-key-pair.pem ec2-user@54.72.131.136
# ssh -i .ssh/bastion-key-pair.pem -L 9090:localhost:9090 ec2-user@54.72.131.136
# ssh -i .ssh/bastion-key-pair.pem -L 27017:localhost:27017 ec2-user@54.72.131.136

