# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "./"
}

dependency "ec2-bastion" {
  config_path = "../bastion"
}

inputs = {
  ec2_instance_id = dependency.ec2-bastion.outputs.id
}
