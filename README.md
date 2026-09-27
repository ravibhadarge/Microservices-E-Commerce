# E-Commerce EKS Terraform Project

Multi-environment Terraform infrastructure for E-Commerce microservices platform on AWS EKS.

## Project Structure

```
terraform-restructured/
├── bootstrap/              # Bootstrap S3 and DynamoDB for Terraform state
├── modules/
│   ├── vpc/                # VPC, subnets, IGW, NAT
│   ├── ec2_jumphost/       # Jumphost with auto-install tools
│   ├── eks/                # EKS cluster and node groups
│   ├── dockerhub/          # Docker Hub configuration
│   └── s3/                 # S3 buckets for application data
└── environments/
    ├── dev/                # Development environment
    ├── staging/            # Staging environment
    └── production/         # Production environment
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- SSH key pair named "pc" in AWS (or update key_name in each environment)

## Quick Start

### 1. Bootstrap (run once)

```bash
cd bootstrap
terraform init
terraform apply
```

### 2. Deploy Dev Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 3. Access Jumphost and Jenkins

After apply completes, wait 10 minutes for the user_data script to install all tools.

```bash
# Get jumphost IP
terraform output jumphost_public_ip

# SSH into jumphost
ssh -i ~/pc.pem ec2-user@<jumphost-ip>

# Check install progress
sudo tail -f /var/log/user-data.log
```

Jenkins will be available at: `http://<jumphost-ip>:8080`
- Username: `admin`
- Password: `admin`

### 4. Deploy Staging and Production

```bash
cd environments/staging
terraform init
terraform apply

cd environments/production
terraform init
terraform apply
```

## Environments

| Environment | VPC CIDR | EKS Version | Nodes | Instance Type |
|-------------|----------|-------------|-------|---------------|
| dev         | 10.0.0.0/16  | 1.35 | 2 | c7i-flex.large |
| staging     | 10.1.0.0/16  | 1.35 | 2 | c7i-flex.large |
| production  | 10.2.0.0/16  | 1.35 | 3 | c7i-flex.large |

## Auto-Installed Tools on Jumphost

- Docker
- Java 21 (Amazon Corretto)
- Jenkins (auto-configured with admin/admin)
- Node.js 22
- AWS CLI v2
- kubectl
- Helm
- Terraform
- eksctl
- GitHub CLI
- Trivy
- Maven
- Git

## Docker Hub

All microservices use Docker Hub repositories with prefix: `ravibhadarge/ecommerce-<env>-<service>`

## Notes

- The jumphost uses `user_data` to automatically install all DevOps tools on first boot
- Jenkins is pre-configured with username `admin` and password `admin`
- EKS nodes are deployed in public subnets (no NAT Gateway to save costs)
- Each environment has its own isolated VPC and EKS cluster
