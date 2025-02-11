# local dev with localstack

## prerequistite

Local versions of Terraform and Terragrunt are required for local environment.

- latest terraform

```bash
# Update the package list
sudo apt update

# Install required dependencies
sudo apt install -y gnupg software-properties-common curl

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update
sudo apt install terraform
```

- latest terragrunt

```bash
# Download the latest Terragrunt binary
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
wget https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64

# Move to a directory in your PATH
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Make the binary executable
sudo chmod +x /usr/local/bin/terragrunt
```

- check versions

```bash
terraform -v
terragrunt -v
```

At time of install ...

- `Terraform v1.10.3`
- `Terragrunt v0.70.4`

According to the [Terraform Registry AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) docs, `hashicorp/aws` version `5.81.0` is compatible with terraform versions above `0.13`.

- Terragrunt autocomplete install

```bash
terragrunt --install-autocomplete
```

Once the autocomplete support is installed, you will need to restart your shell.

- Set dummy creds 

```bash
export AWS_ACCESS_KEY_ID="fake"
export AWS_SECRET_ACCESS_KEY="fake"
export AWS_DEFAULT_REGION="eu-west-1"
```

- Set up state bucket

```bash
awslocal s3 mb s3://local-cc-infra-terraform-state
```


see awslocal below



## start localstack

```
docker run -d  \
  -p 4566:4566 \
  --name localstack \
  localstack/localstack 
```

## setup localstack alias (optional)
```
alias awslocal="aws --endpoint-url=http://localhost:4566"
```


## install an s3 resource
```
cd storage/s3/example-bucket
terragrunt init
terragrunt apply
```

## list buckets 
```
$ awslocal s3 ls
2024-12-20 14:18:18 local-cc-infra-terraform-state
2024-12-20 14:28:59 local-cc-infra-test-bucket-001
```



