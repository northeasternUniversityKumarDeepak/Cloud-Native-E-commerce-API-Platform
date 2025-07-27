# Deployment Guide

This guide walks you through deploying the Cloud-Native E-commerce API Platform from development to production.

## Prerequisites

### Required Tools
- **AWS CLI** (v2.0+) - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Terraform** (v1.0+) - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **Packer** (v1.7+) - [Installation Guide](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
- **Node.js** (v16+) - [Installation Guide](https://nodejs.org/)

### AWS Account Setup
1. Create AWS account
2. Configure IAM user with appropriate permissions
3. Set up AWS CLI credentials
4. Create S3 bucket for Terraform state (optional but recommended)

## Step-by-Step Deployment

### 1. Environment Configuration

#### Configure AWS CLI
```bash
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1
# Default output format: json
```

#### Verify AWS Connection
```bash
aws sts get-caller-identity
```

### 2. Prepare Application Code

#### Clone and Setup
```bash
cd "Cloud Project/webapp"
npm install
```

#### Configure Environment
```bash
cp .env.example .env
# Edit .env with your configuration
```

#### Run Tests
```bash
npm test
```

### 3. Build Custom AMI

#### Prepare Application Bundle
```bash
cd webapp
zip -r ../webapp.zip . -x "node_modules/*" "test/*" ".env*"
```

#### Build AMI with Packer
```bash
cd webapp/packer

# Set variables
export AWS_REGION="us-east-1"
export SUBNET_ID="subnet-xxxxxxxx"  # Use default subnet for now
export ZIP_FILE_PATH="../../webapp.zip"

# Build AMI
packer build \
  -var "aws_region=${AWS_REGION}" \
  -var "subnet_id=${SUBNET_ID}" \
  -var "zip_file_path=${ZIP_FILE_PATH}" \
  app.pkr.hcl
```

#### Note the AMI ID
```bash
# Packer will output something like:
# AMI: ami-0123456789abcdef0
```

### 4. Deploy Infrastructure

#### Configure Terraform Variables
```bash
cd aws-infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Network Configuration
vpc_cidr_block = "10.0.0.0/16"
public_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets_cidr = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

# EC2 Configuration
ami = "ami-0123456789abcdef0"  # Your AMI ID from step 3
instance_type = "t3.micro"
key_name = "your-ec2-key-pair"

# Database Configuration
database_username = "admin"
database_password = "SecurePassword123!"
database_name = "webapp_production"
db_identifier = "webapp-prod-db"

# Domain Configuration
root_domain = "yourdomain.com"
aws_account_number = "123456789012"

# Regional Configuration
region = "us-east-1"
profile = "default"
```

#### Initialize Terraform
```bash
terraform init
```

#### Plan Deployment
```bash
terraform plan -var-file="terraform.tfvars"
```

#### Deploy Infrastructure
```bash
terraform apply -var-file="terraform.tfvars"
```

### 5. Post-Deployment Configuration

#### Get Infrastructure Outputs
```bash
terraform output
```

This will show:
- Load Balancer DNS name
- RDS endpoint
- S3 bucket name

#### Update Application Configuration
Update your application's environment variables with the infrastructure outputs:

```bash
# Example outputs
DB_HOST=webapp-prod-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com
AWS_S3_BUCKET_NAME=webapp-prod-images-bucket-xxxxx
```

#### Rebuild and Deploy Updated AMI
```bash
# Update .env with production values
# Rebuild application bundle
cd webapp
zip -r ../webapp.zip . -x "node_modules/*" "test/*" ".env.example"

# Build new AMI
cd packer
packer build \
  -var "aws_region=${AWS_REGION}" \
  -var "subnet_id=${PRIVATE_SUBNET_ID}" \
  -var "zip_file_path=${ZIP_FILE_PATH}" \
  app.pkr.hcl

# Update launch configuration with new AMI
# This will trigger rolling update of instances
```

### 6. SSL Certificate Setup

#### Request Certificate via AWS Certificate Manager
```bash
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names *.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

#### Validate Domain Ownership
Follow the DNS validation process in AWS Console.

#### Update Load Balancer
Add HTTPS listener with the certificate through AWS Console or Terraform.

### 7. Domain Configuration

#### Update DNS Records
Point your domain to the Load Balancer:

```
Type: A (Alias)
Name: yourdomain.com
Value: your-load-balancer-dns-name.elb.amazonaws.com
```

#### Verify Deployment
```bash
curl https://yourdomain.com/healthz
```

## Environment-Specific Configurations

### Development Environment
```hcl
# terraform.tfvars for dev
instance_type = "t3.micro"
database_instance_class = "db.t3.micro"
min_size = 1
max_size = 2
desired_capacity = 1
```

### Production Environment
```hcl
# terraform.tfvars for prod
instance_type = "t3.small"
database_instance_class = "db.t3.small"
min_size = 2
max_size = 6
desired_capacity = 3
multi_az = true
backup_retention_period = 7
```

## Monitoring Setup

### CloudWatch Alarms
```bash
# CPU Utilization
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPUUtilization" \
  --alarm-description "CPU utilization is too high" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80.0 \
  --comparison-operator GreaterThanThreshold
```

### Log Groups
```bash
# Create log group for application logs
aws logs create-log-group --log-group-name /aws/ec2/webapp
```

## Troubleshooting

### Common Issues

#### 1. AMI Build Fails
```bash
# Check Packer logs
packer build -debug app.pkr.hcl

# Common fixes:
# - Verify subnet_id is correct
# - Check IAM permissions
# - Ensure zip file exists
```

#### 2. Terraform Apply Fails
```bash
# Check Terraform state
terraform state list

# Common fixes:
# - Verify AWS credentials
# - Check resource limits
# - Review variable values
```

#### 3. Application Not Accessible
```bash
# Check instance health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check security groups
aws ec2 describe-security-groups --group-ids <security-group-id>

# Check application logs
aws logs tail /aws/ec2/webapp --follow
```

#### 4. Database Connection Issues
```bash
# Test database connectivity from EC2
mysql -h your-rds-endpoint -u admin -p

# Check security group rules
# Verify subnet group configuration
```

## Rollback Procedures

### Application Rollback
```bash
# Revert to previous AMI
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-asg \
  --launch-configuration-name old-launch-config

# Trigger instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name webapp-asg
```

### Infrastructure Rollback
```bash
# Use Terraform to revert changes
terraform apply -var-file="previous-terraform.tfvars"

# Or destroy and recreate
terraform destroy -var-file="terraform.tfvars"
```

## Performance Optimization

### Auto Scaling Policies
```bash
# Scale up policy
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name webapp-asg \
  --policy-name scale-up \
  --policy-type StepScaling \
  --adjustment-type ChangeInCapacity \
  --step-adjustments MetricIntervalLowerBound=0,ScalingAdjustment=1
```

### Database Optimization
- Enable Performance Insights
- Configure parameter groups
- Set up read replicas for read-heavy workloads

### Caching
- Implement Redis for session storage
- Use CloudFront for static content delivery
- Enable database query caching

## Security Hardening

### Post-Deployment Security
1. **Rotate Access Keys**: Regularly rotate AWS access keys
2. **Update Security Groups**: Remove unnecessary access
3. **Enable GuardDuty**: For threat detection
4. **Configure WAF**: For application-level protection
5. **Patch Management**: Regular OS and software updates

### Compliance
- Enable AWS Config for compliance monitoring
- Set up CloudTrail for audit logging
- Implement backup and disaster recovery procedures
