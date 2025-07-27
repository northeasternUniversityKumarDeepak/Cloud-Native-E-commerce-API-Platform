# Infrastructure Documentation

## Overview
This document describes the AWS infrastructure components and their configuration managed through Terraform.

## Architecture Diagram

```
Internet Gateway
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                        VPC                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  Public Subnet  │  │  Public Subnet  │  │Public Subnet │ │
│  │      AZ-a       │  │      AZ-b       │  │     AZ-c     │ │
│  │                 │  │                 │  │              │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │              │ │
│  │ │Load Balancer│ │  │ │     NAT     │ │  │              │ │
│  │ └─────────────┘ │  │ │   Gateway   │ │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Private Subnet  │  │ Private Subnet  │  │Private Subnet│ │
│  │      AZ-a       │  │      AZ-b       │  │     AZ-c     │ │
│  │                 │  │                 │  │              │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌──────────┐ │ │
│  │ │EC2 Instances│ │  │ │EC2 Instances│ │  │ │    RDS   │ │ │
│  │ │(Auto Scaling│ │  │ │(Auto Scaling│ │  │ │ Database │ │ │
│  │ │    Group)   │ │  │ │    Group)   │ │  │ └──────────┘ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Virtual Private Cloud (VPC)
- **CIDR Block**: Configurable (default: 10.0.0.0/16)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### 2. Subnets

#### Public Subnets
- **Count**: 3 (across different AZs)
- **Purpose**: Load balancers, NAT gateways
- **Route**: Direct access to Internet Gateway

#### Private Subnets  
- **Count**: 3 (across different AZs)
- **Purpose**: Application servers, databases
- **Route**: Access internet via NAT Gateway

### 3. Internet Gateway
- Provides internet access to public subnets
- Attached to VPC

### 4. NAT Gateway
- Enables internet access for private subnets
- Located in public subnet
- Elastic IP attached

### 5. Route Tables

#### Public Route Table
```
Destination: 0.0.0.0/0 → Internet Gateway
Destination: 10.0.0.0/16 → Local
```

#### Private Route Table
```
Destination: 0.0.0.0/0 → NAT Gateway
Destination: 10.0.0.0/16 → Local
```

### 6. Security Groups

#### Application Security Group
- **Inbound Rules**:
  - HTTP (80) from Load Balancer Security Group
  - HTTPS (443) from Load Balancer Security Group
  - SSH (22) from Bastion Host (optional)

#### Database Security Group
- **Inbound Rules**:
  - MySQL (3306) from Application Security Group

#### Load Balancer Security Group
- **Inbound Rules**:
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0

### 7. EC2 Instances

#### Launch Configuration
- **AMI**: Custom AMI built with Packer
- **Instance Type**: Configurable (default: t3.micro)
- **Storage**: 
  - Root Volume: 20GB GP3
  - Encrypted: Yes
- **User Data**: Application startup script

#### Auto Scaling Group
- **Min Size**: 2
- **Max Size**: 6
- **Desired Capacity**: 3
- **Health Check Type**: ELB
- **Health Check Grace Period**: 300 seconds

### 8. Application Load Balancer
- **Scheme**: Internet-facing
- **Type**: Application Load Balancer
- **Listeners**: 
  - HTTP (80) → Redirect to HTTPS
  - HTTPS (443) → Target Group
- **SSL Certificate**: AWS Certificate Manager

### 9. RDS Database

#### Configuration
- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro
- **Storage**: 20GB GP3
- **Multi-AZ**: Yes (for production)
- **Backup Retention**: 7 days
- **Encryption**: Enabled

#### Subnet Group
- Private subnets across multiple AZs
- Ensures high availability

### 10. S3 Bucket
- **Purpose**: Static file storage (images)
- **Versioning**: Enabled
- **Encryption**: AES-256
- **Public Access**: Blocked (access via IAM roles)

## Terraform Variables

### Required Variables
```hcl
# Network Configuration
vpc_cidr_block = "10.0.0.0/16"
public_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets_cidr = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

# EC2 Configuration
ami = "ami-12345678"  # Custom AMI ID
instance_type = "t3.micro"
key_name = "your-key-pair"

# Database Configuration
database_username = "admin"
database_password = "secure-password"
database_name = "webapp_db"

# Domain Configuration
root_domain = "yourdomain.com"
```

### Optional Variables
```hcl
region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
instance_vol_size = 20
instance_vol_type = "gp3"
```

## Deployment Commands

### Initialize Terraform
```bash
cd aws-infra
terraform init
```

### Plan Infrastructure
```bash
terraform plan -var-file="terraform.tfvars"
```

### Apply Infrastructure
```bash
terraform apply -var-file="terraform.tfvars"
```

### Destroy Infrastructure
```bash
terraform destroy -var-file="terraform.tfvars"
```

## Monitoring & Logging

### CloudWatch
- **EC2 Metrics**: CPU, Memory, Disk, Network
- **RDS Metrics**: Connections, CPU, Storage
- **ALB Metrics**: Request count, latency, errors
- **Custom Metrics**: Application-specific metrics

### CloudTrail
- **API Logging**: All AWS API calls
- **Data Events**: S3 object-level operations

### VPC Flow Logs
- **Network Traffic**: Accept/Reject logs
- **Storage**: CloudWatch Logs

## Security Considerations

### Network Security
- Private subnets for application and database tiers
- Security groups with least privilege access
- NACLs for additional network-level security

### Data Security
- Encryption at rest for RDS and S3
- Encryption in transit with TLS/SSL
- IAM roles for service-to-service communication

### Access Control
- IAM roles and policies
- MFA for administrative access
- Key rotation policies

## Cost Optimization

### EC2
- Right-sizing instances based on usage
- Spot instances for non-critical workloads
- Reserved instances for predictable workloads

### Storage
- S3 Intelligent Tiering
- EBS GP3 for better price/performance
- Lifecycle policies for log retention

### Monitoring
- CloudWatch cost anomaly detection
- AWS Cost Explorer for usage analysis
- Budgets and billing alerts

## Disaster Recovery

### Backup Strategy
- RDS automated backups (7-day retention)
- S3 cross-region replication
- AMI snapshots for quick recovery

### High Availability
- Multi-AZ deployment
- Auto Scaling for automatic recovery
- Health checks and automatic replacement

## Scaling Considerations

### Horizontal Scaling
- Auto Scaling Groups respond to metrics
- Load balancer distributes traffic
- Stateless application design

### Vertical Scaling
- Instance type can be changed
- RDS can be scaled up/down
- Storage can be increased dynamically
