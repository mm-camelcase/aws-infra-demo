# Terragrunt Stacks Documentation

## Overview
Terragrunt stacks are an organisational approach to managing infrastructure-as-code using Terragrunt. They allow the grouping of related Terraform modules into logical units that can be managed independently. This approach simplifies the deployment and maintenance of infrastructure by separating concerns and promoting modularity.

## What Are Terragrunt Stacks?
A Terragrunt stack represents a collection of Terraform modules and configurations that work together to provision a specific part of your infrastructure. Examples include a stack for ECS clusters, another for EKS clusters, and shared resources like networking and storage.

### Key Characteristics of Terragrunt Stacks:
- **Modular**: Each stack operates as an independent unit with its own configuration and state.
- **Reusable**: Common components (e.g., networking or IAM roles) can be reused across multiple stacks.
- **Scalable**: New stacks can be added as the infrastructure grows or changes.
- **Environment-Specific**: Stacks can be configured for different environments (e.g., dev, non-prod, prod) using Terragrunt's `inputs` and `dependency` blocks.

## Why Use Terragrunt Stacks?
Terragrunt stacks bring several benefits to managing your infrastructure:

1. **Simplified Management**:
   - Reduce complexity by organising infrastructure into logical units.
   - Manage dependencies between stacks explicitly.

2. **Consistency Across Environments**:
   - Define reusable modules and configuration patterns.
   - Ensure consistency across regions or environments using Terragrunt’s environment-based directory structure.

3. **Automation-Friendly**:
   - Easily integrate with CI/CD pipelines for automated provisioning and deployment.

4. **Reduced Blast Radius**:
   - Limit the impact of changes to a single stack, minimising risk in production environments.

## Setting Up Terragrunt Stacks
1. **Directory Structure**:
   Organise your stacks using directories for different environments and regions. For example:
   ```plaintext
   infrastructure/
   ├── non-prod/
   │   └── eu-west-1/
   │       ├── ecs/
   │       │   └── terragrunt.hcl
   │       └── eks/
   │           └── terragrunt.hcl
   └── prod/
       └── us-east-1/
           ├── ecs/
           │   └── terragrunt.hcl
           └── eks/
               └── terragrunt.hcl
   ```

2. **Mocking Dependencies**:
   Mocking dependencies is necessary because running a `run-all plan` command in Terragrunt can break if required resources do not exist. For example, a stack may depend on outputs from another stack (e.g., VPC ID, subnets). During testing or local development, you can use mocked values to avoid failures.

   To mock dependencies, use tools like [LocalStack](https://localstack.cloud/) to emulate AWS services, or define placeholder outputs in your Terragrunt configurations. This ensures that `plan-all` succeeds without requiring actual resources to be provisioned.

   Example:
   ```hcl
   dependency "networking" {
     config_path = "../common/networking"
   }

   dependency "mocked" {
     mock_outputs = {
       vpc_id = "mock-vpc-id"
       subnet_ids = ["mock-subnet-1", "mock-subnet-2"]
     }
   }

   inputs = {
     vpc_id = dependency.networking.outputs.vpc_id
   }
   ```

   This approach allows for smooth planning and development workflows while ensuring that dependencies are properly tested and defined.

3. **Automating Deployment**:
   Set up a CI/CD pipeline using tools like GitHub Actions, as demonstrated in the `deploy-demo.yml` file. Automate plan and apply steps for individual stacks based on changes detected in the relevant directories.

## Example: ECS and EKS Stacks

### ECS Stack
- Provisions an ECS cluster and related resources.
- Example configuration in `ecs/terragrunt.hcl`:
  ```hcl
  terraform {
    source = "../modules/ecs"
  }

  inputs = {
    cluster_name = "ecs-cluster-nonprod"
    region       = "eu-west-1"
  }
  ```

### EKS Stack
- Provisions an EKS cluster with worker nodes.
- Example configuration in `eks/terragrunt.hcl`:
  ```hcl
  terraform {
    source = "../modules/eks"
  }

  inputs = {
    cluster_name = "eks-cluster-nonprod"
    region       = "eu-west-1"
    node_count   = 3
  }
  ```


## Learn More
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terraform Modules Best Practices](https://www.terraform.io/docs/modules/index.html)
- [LocalStack Documentation](https://localstack.cloud/docs/)

By using Terragrunt stacks, you can effectively manage your infrastructure, ensure consistency across environments, and simplify deployments. This approach is ideal for large-scale, multi-environment setups.

