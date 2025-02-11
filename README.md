# AWS Infrastructure Demo

## About the Demo Infrastructure
This repository showcases an end-to-end architecture that spans networking, security, services, and the deployment of a static application. The demo infrastructure serves as a complete reference implementation that highlights best practices for building secure, scalable, and well-orchestrated cloud solutions.

### **Why Terragrunt?**
- **Modular & Reusable**: Enables structured and consistent Terraform deployments.
- **Environment Management**: Simplifies managing multiple environments (e.g., dev, staging, prod).
- **DRY (Don't Repeat Yourself)**: Reduces duplication by managing Terraform configurations centrally.

### **Use of External Terraform Modules**
- **Reliability**: Leverages battle-tested modules from the **Terraform Registry**.
- **Faster Iteration**: Reuses existing infrastructure components without reinventing them.
- **Maintainability**: Keeps the infrastructure **clean, composable, and easy to update**.

### **Automation with GitHub Actions**
- **CI/CD for Infrastructure**: Automates Terraform/Terragrunt workflows.
- **Secure OIDC Integration**: Eliminates long-lived AWS credentials.
- **Approval Workflow**: Ensures controlled, auditable infrastructure changes.

This setup enables **scalable, secure, and automated infrastructure management** with minimal manual intervention.

## Table of Contents

- [About the Demo Infrastructure](#about-the-demo-infrastructure)
- [Architecture](#architecture)
  - [High-Level Architecture](#high-level-architecture)
  - [Key Features](#key-features)
  - [Application Flow](#application-flow)
- [Domain Configuration](#domain-configuration)
- [Environment Details](#environment-details)
- [Accessing Cloud Resources](#accessing-cloud-resources)
  - [SSM Bastion Usage](#ssm-bastion-usage)
  - [ECS Container Access via exec](#ecs-container-access-via-exec)
- [Workflows](#workflows)
- [Database Setup](#database-setup)
- [Local Setup for Testing](#local-setup-for-testing)


## Architecture

### High-Level Architecture
The overall architecture is depicted in the following diagram:

![Infrastructure](assets/images/infra.jpeg)

This diagram represents the services within a VPC connected to public and private subnets, AWS ECS, RDS, and other critical components. 


### Key Features

**1. Networking**  
- **Private & Public Subnets:** Ensures security and scalability.  
- **Load Balancing:** Uses **NLB** for internal services and **CloudFront** for static content delivery.  

**2. Security**  
- **Private Subnets:** Keeps sensitive services and databases inaccessible from the internet.  
- **WAF & API Gateway:** Protects against exploits and secures API access.  
- **OAuth Flow:** Secure authentication using **Keycloak** and OAuth 2.0.  

**3. Access Management**  
- **SSM Bastion:** Secure **AWS SSM-based** access for backend services and databases, eliminating the need for SSH key management.  

**4. Service Architecture**  
- **ECS & ECR:** Services are containerized in **AWS ECS**, with images stored in **ECR**.  
- **Service Discovery:** **AWS Cloud Map** enables dynamic service registration and discovery.  
- **Secrets Management:** Uses **AWS Parameter Store** for secrets and credentials, a **cost-effective alternative** to Secrets Manager.  
- **Logging & Monitoring:** Integrated with **Amazon CloudWatch** for centralized logs.  

**5. Service Security**  
- **Private Networking:** ECS Fargate microservices and **RDS databases** run in private networks.  
- **API Security:** APIs are secured with **OAuth 2.0** for controlled access.  
- **DevOps Access:** Secure **bastion access** for debugging and maintenance.  

**6. Static Application**  
- **Vue-Based App:** Hosted in **S3**, secured with **Keycloak authentication**. See [Application Flow](#application-flow) section.

**7. Automation**  
- **Infrastructure as Code:** Managed with **Terraform/Terragrunt**.  
- **CI/CD:** Automated workflows via **GitHub Actions**.  


### Application Flow

<table>
  <tr>
    <td style="padding: 10px; border: none; vertical-align: top;">
      <ul>
        <li><strong>Hosting & Security:</strong> The Vue.js application is hosted in S3, served via CloudFront, and protected by AWS WAF to mitigate web threats.</li>
        <li><strong>User Authentication:</strong> A Keycloak-based login, implementing OAuth 2.0 Authorization Code Flow.</li>
        <li><strong>Backend Communication:</strong> After authentication, the frontend interacts with a Spring Boot service running on ECS Fargate. API requests are secured using OAuth 2.0, ensuring resource protection and controlled access.</li>
      </ul>
    </td>
    <td style="padding: 10px; border: none; vertical-align: top;">
      <img src="assets/images/app.gif" width="300"/>
    </td>
  </tr>
</table>



## Domain Configuration

The application and its services are accessible through the following domain setup:

| **Service** | **URL** | **Details** |
|------------|----------------------------|--------------|
| **Frontend (Vue App)** | [app.camelcase.club](https://app.camelcase.club) | The **Vue app** is hosted in **S3** and served via **CloudFront**, protected by by **AWS WAF**  |
| **Authentication (Keycloak)** | [auth.camelcase.club](https://auth.camelcase.club) | Authentication is managed via **Keycloak**  |
| **Backend APIs** | [api.camelcase.club](https://api.camelcase.club) |  Backend **APIs** are exposed at `api.camelcase.club`, secured with **OAuth 2.0**, and protected by by **AWS WAF** |

**Note:** In this demo DNS configuration is managed externally from AWS, with CNAME records pointing to the appropriate AWS resources.
 

## Environments

This walkthrough is based on a **single demo environment**, but the Infrastructure as Code (IaC) setup is designed to support additional environments effortlessly.

- **Scalable IaC Structure:** The Terraform/Terragrunt configuration is modular, making it easy to extend and add new environments as needed.
- **Multi-Account Support:** The infrastructure can be configured to split environments across separate AWS accounts. For example:
  - **Non-prod (Dev & Staging)** in one AWS account.
  - **Production** in a separate AWS account for security and isolation.
- **Terragrunt Compatibility:** The current structure fully supports multi-environment deployments, ensuring streamlined provisioning and consistency across accounts.

## Accessing Cloud Resources

The following table outlines how different resources are accessed across environments:

| **Resource**         | **Access Method**                                    | **Notes** |
|----------------------|------------------------------------------------------|----------|
| **SSM Bastion**      | **AWS Systems Manager Session Manager** (`ssm start-session`) | Secure access to backend services and databases without exposing SSH. |
| **Backend & ECS Services** | Access via **API Gateway** for APIs and **ECS** `exec` for container access | Services are containerized and secured with OAuth 2.0. |
| **Databases**       | Access via **SSM Bastion** with port forwarding       | No direct internet exposure for RDS or other data stores. |



### **SSM Bastion Usage**
To securely connect to backend services or databases, use **AWS SSM Session Manager**:

**Advantages of SSM over SSH:**  
✅ **No open SSH ports** → Eliminates the need for security group rules for SSH.  
✅ **No SSH keys required** → Uses IAM-based authentication.  
✅ **Fully logged & auditable** → All sessions are recorded in AWS CloudTrail.  


#### **Bastion Access**

```bash

ec2_bridge_id=i-008045bbe4f75517b   # EC2 Bastion Id

## Bastian
aws ssm start-session --target $ec2_bridge_id
```


#### **Database Access**

Database access via **SSM Port Forwarding**.

```bash

ec2_bridge_id=i-008045bbe4f75517b   # EC2 Bastion Id
db_url=demo-cc-infra-db.cf2okowc4emp.eu-west-1.rds.amazonaws.com  # DB URL

## PostgreSQL
aws ssm start-session \
    --target $ec2_bridge_id \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"${db_url}\"],\"portNumber\":[\"5432\"], \"localPortNumber\":[\"5432\"]}"
```

- Update `ec2_bridge_id` and `db_url`
- Connect to database via ``localhost``

<img src="assets/images/db_connection.png" width="400"/>


### **ECS Container Access via** ``exec``

```bash

ec2_bridge_id=i-008045bbe4f75517b   # EC2 Bastion Id

## service
env=demo
service_name=keycloak-service

task_arn=$(aws ecs list-tasks --cluster "${env}-cc-infra-cluster" --service-name ${env}-cc-infra-${service_name} --query "taskArns[]" --output text)

aws ecs execute-command \
  --cluster "${env}-cc-infra-cluster" \
  --task $task_arn \
  --container $service_name \
  --command "sh" \
  --interactive \
  --region eu-west-1
```

## Workflows


## **Terragrunt/Terraform Workflows with GitHub Actions**

This infrastructure leverages **GitHub Actions** to run **Terraform workflows** securely using **OpenID Connect (OIDC) Identity Provider in AWS**. For detailed information on how OIDC is configured and used, refer to the [OIDC Authentication Guide](https://github.com/mm-camelcase/aws-infra-demo/tree/main/docs/02-github-actions-auth).

### **Terraform Workflows**
Two Terragrunt/Terraform workflows are implemented to streamline infrastructure management:

1. **Resource Workflow** (Recomended):
   - Focused on managing individual Terraform resources, such as S3 buckets or RDS databases.
   - Best suited for making isolated changes or updates to specific components.

2. **Stack Workflow** (Experimental):
   - Manages larger infrastructure stacks or modules, such as VPCs, ECS clusters, or entire environments.
   - Ensures consistency and coordination for complex deployments.
   - See [Terragrunt Stacks Doc](https://github.com/mm-camelcase/aws-infra-demo/tree/main/docs/03-stacks)


---

### **Workflow Steps**

Below is a visual representation of the Terraform workflow process:

<table>
  <tr>
    <th style="padding: 10px; border: none; text-align: left; vertical-align: top;"><b>Step 1: Select Action and Resource</b></th>
    <th style="padding: 10px; border: none; text-align: left; vertical-align: top;"><b>Step 2: Review Terraform Plan</b></th>
    <th style="padding: 10px; border: none; text-align: left; vertical-align: top;"><b>Step 3: Approve</b></th>
  </tr>
  <tr>
    <td style="padding: 10px; border: none; vertical-align: top;"><img src="assets/images/workflow1.png" width="300"/></td>
    <td style="padding: 10px; border: none; vertical-align: top;">
      <img src="assets/images/workflow2.png" width="300"/>
    </td>
    <td style="padding: 10px; border: none; vertical-align: top;"><img src="assets/images/workflow3.png" width="400"/></td>
  </tr>
</table>  


#### **Step Details**
1. **Select Action and Resource:**
   - The workflow allows users to choose the Terraform action (e.g., `plan`, `apply`, `destroy`) and the specific resource to manage.
   - Regions and modules are selected dynamically via the workflow.

2. **Review Terraform Plan:**
   - After initiating the action, the workflow generates a detailed Terraform plan.
   - Resource changes are clearly displayed, categorized as `Create`, `Update`, `Delete`, etc.

3. **Approve:**
   - The plan requires manual approval before applying any changes to the infrastructure.
   - Approval ensures no accidental changes are applied.

---

### **Benefits of this Setup**
- **Secure Authentication:** Eliminates the need for long-lived AWS credentials by using OIDC to generate short-lived tokens.
- **Simplified CI/CD:** Seamless integration of GitHub Actions with AWS for automated Terraform runs.
- **Controlled Changes:** Manual approval ensures no unintended changes to resources.
- **Granular Access Control:** IAM roles ensure the workflow operates with the least privilege necessary.

## **Database Setup**

Once the **RDS instance** is provisioned, see [database init](https://github.com/mm-camelcase/aws-infra-demo/tree/main/docs/04-rds-db-init)

## **Local Setup for Testing**

For local development and testing, this project includes a **LocalStack-based setup** that allows bootstrapping essential AWS services for testing service configurations.

- LocalStack provides a **lightweight AWS cloud emulator**, ideal for local development.
- This setup enables **testing authentication, API services, and resource provisioning** without deploying to AWS.

📌 **Refer to the full LocalStack setup guide here:**  
🔗 [LocalStack Documentation](https://github.com/mm-camelcase/aws-infra-demo/tree/main/docs/01-localstack)

This ensures a **fast, isolated** environment for development and validation.


