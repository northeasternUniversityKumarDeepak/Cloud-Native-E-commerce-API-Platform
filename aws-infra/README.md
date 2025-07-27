# aws-infra

Author:  `Deepak Kumar`

Pre-requisites:
- Install and Configure AWS Command Line Interface
- Install Terraform


Build and Deploy:
- Clone the repository
- cd aws-infra


Run these commands:


`terraform fmt` - Format the files

`terraform init` - Initialize terraform environment

`terraform plan` - Generate & show an execution plan

`terraform apply` - Creation of networking resources

`terraform destroy` - Cleanup of networking resources


##  Command for importing the certificate 


aws acm import-certificate  --certificate fileb://`path_of_crt` --private-key fileb://`path_of_private_key` --certificate-chain fileb://`path_of_ca_bundle` --profile prod 
