# Cloud-Native E-commerce API Platform

**Author:** Deepak Kumar  

## 🎯 Project Overview

This is a full-stack cloud-native e-commerce platform built with Node.js and deployed on AWS infrastructure. The project demonstrates modern cloud architecture patterns including Infrastructure as Code, containerization, and automated deployment pipelines.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Users/Clients │────│  Load Balancer   │────│   EC2 Instances │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                              ┌─────────────────────────────────────┐
                              │           Application               │
                              │  • User Management API             │
                              │  • Product Management API          │
                              │  • Image Upload/Management         │
                              │  • Authentication & Authorization  │
                              └─────────────────────────────────────┘
                                                         │
                              ┌─────────────────────────────────────┐
                              │            Data Layer              │
                              │  • RDS MySQL Database              │
                              │  • S3 for Image Storage            │
                              │  • CloudWatch for Monitoring       │
                              └─────────────────────────────────────┘
```

## 📁 Project Structure

```
📦 Cloud Project/
├── 🏗️ aws-infra/                 # Infrastructure as Code (Terraform)
│   ├── main.tf                   # Main Terraform configuration
│   ├── providers.tf              # AWS provider configuration
│   ├── variables.tf              # Variable definitions
│   ├── terraform.tfvars          # Environment-specific values
│   └── modules/
│       └── networking/           # VPC, Subnets, Security Groups
├── 🚀 webapp/                    # Node.js Web Application
│   ├── 📱 API Endpoints
│   │   ├── controllers/          # Business logic
│   │   ├── routes/              # API route definitions
│   │   └── auth.js              # Authentication middleware
│   ├── 🗄️ Data Layer
│   │   ├── config/              # Database & service configurations
│   │   └── database.js          # Database connection
│   ├── 📦 Deployment
│   │   └── packer/              # AMI building scripts
│   └── 🧪 Testing
│       └── test.js              # API test suites
└── 📚 Documentation             # Project documentation
```

## 🎯 Features

### 👥 User Management
- **POST** `/v1/user` - Create new user account
- **GET** `/v1/user/:id` - Get user profile (authenticated)
- **PUT** `/v1/user/:id` - Update user profile (authenticated)

### 🛍️ Product Management
- **POST** `/v1/product` - Create new product (authenticated)
- **GET** `/v1/product/:id` - Get product details
- **PUT** `/v1/product/:id` - Update entire product (authenticated)
- **PATCH** `/v1/product/:id` - Partial product update (authenticated)
- **DELETE** `/v1/product/:id` - Delete product (authenticated)

### 🖼️ Image Management
- **GET** `/v1/product/:productId/image` - List all product images
- **GET** `/v1/product/:productId/image/:imageId` - Get specific image
- **POST** `/v1/product/:productId/image` - Upload product image
- **DELETE** `/v1/product/:productId/image/:imageId` - Delete image

### 🏥 Health Monitoring
- **GET** `/healthz` - Application health check endpoint

## 🛠️ Technology Stack

### Backend
- **Runtime:** Node.js with Express.js
- **Database:** MySQL with Sequelize ORM
- **Authentication:** bcrypt for password hashing
- **File Upload:** Multer for handling multipart/form-data
- **Cloud Storage:** AWS S3 for image storage
- **Monitoring:** Winston for logging, StatsD for metrics

### Infrastructure
- **IaC:** Terraform for infrastructure provisioning
- **Cloud Provider:** Amazon Web Services (AWS)
- **Compute:** EC2 instances with Auto Scaling
- **Database:** RDS MySQL
- **Storage:** S3 for static assets
- **Monitoring:** CloudWatch
- **Image Building:** Packer for AMI creation

### DevOps
- **Testing:** Mocha, Chai, Supertest
- **Environment Management:** dotenv
- **CORS:** Enabled for cross-origin requests

## 🚀 Quick Start

### Prerequisites
- Node.js (v14+)
- MySQL Server
- AWS CLI configured
- Terraform installed
- Packer installed

### 1. Infrastructure Setup
```bash
cd aws-infra
terraform init
terraform plan
terraform apply
```

### 2. Application Setup
```bash
cd webapp
npm install
cp .env.example .env  # Configure your environment variables
node app.js
```

### 3. Testing
```bash
cd webapp
npm test
```

## 🌐 AWS Components

| Service | Purpose |
|---------|---------|
| **EC2** | Application hosting and compute |
| **RDS** | MySQL database hosting |
| **S3** | Image and static file storage |
| **VPC** | Network isolation and security |
| **Security Groups** | Firewall rules |
| **CloudWatch** | Monitoring and logging |
| **AMI** | Custom application images |

## 📋 Environment Variables

Create a `.env` file in the webapp directory:

```env
# Database Configuration
DB_HOST=your-rds-endpoint
DB_USER=your-db-username
DB_PASSWORD=your-db-password
DB_NAME=your-database-name
DB_PORT=3306

# AWS Configuration
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-s3-bucket-name

# Application Configuration
PORT=3000
NODE_ENV=production
```

## 🧪 API Testing

### Health Check
```bash
curl -X GET http://localhost:3000/healthz
```

### Create User
```bash
curl -X POST http://localhost:3000/v1/user \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "password": "securepassword"
  }'
```

### Create Product
```bash
curl -X POST http://localhost:3000/v1/product \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic base64(username:password)" \
  -d '{
    "name": "Sample Product",
    "description": "Product description",
    "sku": "PROD-001",
    "manufacturer": "Sample Corp",
    "quantity": 100
  }'
```

## 🔧 Development Workflow

1. **Local Development**
   - Use local MySQL for database
   - Test APIs with Postman or curl
   - Run test suite with `npm test`

2. **Infrastructure Changes**
   - Modify Terraform files in `aws-infra/`
   - Plan and apply changes
   - Update AMI if needed

3. **Application Deployment**
   - Build new AMI with Packer
   - Update launch configuration
   - Deploy through Auto Scaling Group

## 📚 Next Steps

- [ ] Add comprehensive API documentation (Swagger/OpenAPI)
- [ ] Implement CI/CD pipeline
- [ ] Add container support (Docker)
- [ ] Implement caching layer (Redis)
- [ ] Add API rate limiting
- [ ] Enhance security with JWT tokens
- [ ] Add comprehensive monitoring dashboard

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes and test
4. Submit pull request

## 📄 License

This project is licensed under the MIT License.
