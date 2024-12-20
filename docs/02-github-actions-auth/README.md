# Setting Up AWS Authentication in GitHub Actions for Infrastructure Pipelines

## Overview

AWS Security Token Service (STS) is considered one of the most secure methods for managing credentials and access in AWS. STS allows the creation of temporary, limited-privilege credentials for AWS access. This service is ideal for managing temporary access needs, such as for federated users (users with an identity outside of AWS), cross-account access, or in applications and automated workflows like GitHub Actions.

### Key Points:
- **Temporary Nature**: Credentials are short-term, reducing risk if compromised.
- **Use Cases**: Useful for federated user access, cross-account access, and temporary access in automated workflows (e.g., `infra-core` Actions pipeline).
- **Dynamic Credentials**: STS generates temporary access key ID, secret access key, and a security token.
- **Enhanced Security**: Limits long-term credential exposure and can be tailored with specific permissions and durations.
- **AWS Integration**: Compatible with many AWS services, allowing for secure, temporary access within AWS ecosystems.
- **Expiration Handling**: Systems using temporary credentials must manage their expiration and renewal.

AWS STS provides a secure and flexible solution for managing temporary AWS access, enhancing security posture, especially in dynamic and automated environments.

---

## Setup Steps

### 1. Create an OpenID Connect (OIDC) Identity Provider in AWS:
1. Go to the **IAM** section in the AWS Management Console.
2. Choose **Identity Providers**, then **Add Provider**.
3. Select **OpenID Connect** as the provider type.
4. For the provider URL, use:
   ```
   https://token.actions.githubusercontent.com
   ```
5. For the audience, use:
   ```
   sts.amazonaws.com
   ```

### 2. Create an IAM Role for GitHub Actions:
1. In the IAM section, create a new role.
2. Select **Web identity** as the trusted entity type.
3. Choose the OIDC identity provider you created as the trusted entity.
4. Define a condition to match the GitHub repository that will assume this role. For example:
   ```json
   {
     "StringLike": {
       "token.actions.githubusercontent.com:sub": "repo:invoice-fair/infra-core:*"
     }
   }
   ```
5. Attach policies to this role that grant necessary permissions for your workflow. This ensures that only specific GitHub repositories and branches can assume this role.

### 3. Configure GitHub Actions Workflow:
1. In your GitHub repository, edit your GitHub Actions workflow file.
2. Use the `aws-actions/configure-aws-credentials` action for setting up AWS credentials.
3. Set the `role-to-assume` parameter to the ARN of the IAM role you created.

Example snippet for your workflow file:
```yaml
jobs:
  checks:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: 'Checkout'
        uses: actions/checkout@main

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::262847506086:role/FF-CorePlatform-CICD-Role
          aws-region: eu-west-1

      - name: Check terragrunt HCL
        uses: gruntwork-io/terragrunt-action@v2
        with:
          tf_version: ${{ env.tf_version }}
          tg_version: ${{ env.tg_version }}
          tg_dir: env/${{ env.environment }}/${{ env.region }}/${{ github.event.inputs.resource }}
          tg_command: 'hclfmt --terragrunt-check --terragrunt-diff'
```

### 4. Configure IAM Policy:
1. Configure an IAM Policy with the necessary permissions required by the pipeline.
2. Attach the policy to the role.

---

## References
- [Financefair Platform Documentation](https://invoicefair.atlassian.net/wiki/pages/resumedraft.action?draftId=2913271812&draftShareId=97c0fa6f-90e8-409b-be33-aa0ee393a326)

