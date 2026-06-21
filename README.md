README.md
# 🚀 Infrastructure Drift Detection and Automated Remediation Using Terraform & AWS Lambda

## 📖 Project Overview

This project demonstrates a fully automated Infrastructure Drift Detection and Remediation system on AWS.

The system continuously monitors AWS resources for unauthorized manual changes (configuration drift) and automatically restores them to their approved Terraform-defined state.

The solution uses:

- Terraform for Infrastructure as Code
- AWS Config for Compliance Monitoring
- AWS Lambda for Automated Remediation
- Amazon EventBridge for Scheduled Execution
- Amazon CloudWatch for Audit Logging

---

# 🎯 Project Objectives

- Provision infrastructure using Terraform
- Detect unauthorized manual changes
- Continuously monitor compliance
- Automatically restore approved configurations
- Maintain Infrastructure as Code integrity
- Create a complete audit trail

---

# 🏗️ Architecture

```text
                    Terraform
                         │
                         ▼
        ┌─────────────────────────────┐
        │     AWS Infrastructure      │
        │                             │
        │  EC2 + Security Group + S3  │
        └──────────────┬──────────────┘
                       │
                       ▼
             Manual Changes
           (Configuration Drift)
                       │
                       ▼
                AWS Config
         Detects Non-Compliant State
                       │
                       ▼
                EventBridge
             (Every 5 Minutes)
                       │
                       ▼
                AWS Lambda
         Detect → Remediate → Log
                       │
                       ▼
               CloudWatch Logs
                       │
                       ▼
            Infrastructure Restored
🛠️ Tech Stack
Service	Purpose
Terraform	Infrastructure as Code
AWS EC2	Compute Instance
AWS Security Groups	Network Security
AWS S3	Storage
AWS Config	Drift Detection
AWS Lambda	Auto Remediation
Amazon EventBridge	Scheduling
Amazon CloudWatch	Logging
Python 3.11	Lambda Runtime
📋 Prerequisites

Before starting:

Install Terraform

Download:

https://developer.hashicorp.com/terraform/downloads

Verify:

terraform -version

Expected:

Terraform v1.7.x
Install AWS CLI

Verify:

aws --version
Configure AWS Credentials
aws configure

Enter:

AWS Access Key
AWS Secret Key
Region: us-east-1
Output Format: json
Install VS Code

Recommended Extension:

HashiCorp Terraform
Step 1: Create Project Structure

Create project folder:

mkdir drift-detection-project
cd drift-detection-project

Create directories:

mkdir terraform
mkdir lambda

Expected Structure:

drift-detection-project/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── ec2.tf
│   ├── security_group.tf
│   ├── s3.tf
│   ├── outputs.tf
│   ├── config.tf
│   └── lambda.tf
│
└── lambda/
    └── remediation.py
Step 2: Create Terraform Provider Configuration

Create:

terraform/main.tf

Add:

terraform {
 required_providers {
  aws = {
   source = "hashicorp/aws"
   version = "~> 5.0"
  }

  random = {
   source = "hashicorp/random"
   version = "~> 3.0"
  }
 }

 required_version = ">= 1.3.0"
}

provider "aws" {
 region = var.aws_region
}

data "aws_vpc" "default" {
 default = true
}

data "aws_subnets" "default" {
 filter {
  name = "vpc-id"
  values = [data.aws_vpc.default.id]
 }
}
Step 3: Create Variables

Create:

terraform/variables.tf
variable "aws_region" {
 default = "us-east-1"
}

variable "project_name" {
 default = "drift-detection"
}

variable "ami_id" {
 default = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
 default = "t2.micro"
}
Step 4: Create Security Group

Create:

terraform/security_group.tf
resource "aws_security_group" "project_sg" {

 name   = "${var.project_name}-sg"
 vpc_id = data.aws_vpc.default.id

 ingress {
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
 }

 ingress {
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
 }

 egress {
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
  Name = "${var.project_name}-sg"
  ManagedBy = "Terraform"
 }
}
Step 5: Create EC2 Instance

Create:

terraform/ec2.tf
resource "aws_instance" "project_ec2" {

 ami           = var.ami_id
 instance_type = var.instance_type

 subnet_id = tolist(data.aws_subnets.default.ids)[0]

 vpc_security_group_ids = [
  aws_security_group.project_sg.id
 ]

 tags = {
  Name        = "${var.project_name}-ec2"
  Environment = "Production"
  ManagedBy   = "Terraform"
 }
}
Step 6: Create S3 Bucket

Create:

terraform/s3.tf

Add:

Random bucket suffix
Bucket versioning
AES256 encryption

This ensures:

✅ Unique bucket names

✅ Version protection

✅ Encryption at rest

Step 7: Deploy Infrastructure

Move into Terraform folder:

cd terraform

Initialize:

terraform init

Validate:

terraform validate

Expected:

Success! The configuration is valid.
Step 8: Review Deployment Plan
terraform plan

Expected:

Plan: 5 to add, 0 to change, 0 to destroy

Review all resources carefully.

Step 9: Apply Infrastructure
terraform apply

Type:

yes

Terraform creates:

EC2 Instance
Security Group
S3 Bucket
Bucket Encryption
Bucket Versioning
Step 10: Verify Deployment

Verify EC2:

AWS Console
→ EC2
→ Instances

Expected:

State = Running
Environment = Production
ManagedBy = Terraform

Verify Security Group:

Port 22 → 10.0.0.0/8
Port 80 → 10.0.0.0/8

Verify S3:

Versioning Enabled
AES256 Encryption Enabled
Step 11: Simulate Infrastructure Drift

We intentionally create unauthorized changes.

Drift 1 – Security Group Drift

Navigate:

EC2
→ Security Groups
→ Edit Inbound Rules

Change:

22 → 0.0.0.0/0

Add:

8080 → 0.0.0.0/0

Save.

Drift 2 – EC2 Tag Drift

Navigate:

EC2
→ Instance
→ Tags

Change:

Environment
Production → Development

Add:

ModifiedBy = ManualChange

Save.

Step 12: Verify Terraform Detects Drift

Run:

terraform plan

Terraform should show:

Environment tag change detected
Security Group drift detected
Step 13: Configure AWS Config

Deploy:

terraform apply

AWS Config provisions:

Configuration Recorder
Delivery Channel
Config Bucket
Config Rules
IAM Roles
Step 14: Verify AWS Config

Navigate:

AWS Config
→ Rules

Expected Rules:

drift-detection-ec2-required-tags
drift-detection-restricted-ssh

After a few minutes:

NON_COMPLIANT

Status should appear.

Step 15: Create Lambda Remediation Function

Create:

lambda/remediation.py

Function Responsibilities:

Detect tag drift
Remove unauthorized tags
Restore approved tags
Detect SG drift
Remove unauthorized rules
Restore approved rules
Write logs to CloudWatch
Step 16: Deploy Lambda Infrastructure

Terraform provisions:

Lambda Function
IAM Role
IAM Policies
CloudWatch Log Group
EventBridge Rule
Lambda Permission

Deploy:

terraform apply
Step 17: Verify Lambda

Navigate:

Lambda
→ drift-detection-remediation

Verify:

Runtime = Python 3.11
Timeout = 60 Seconds

Environment Variables:

EC2_INSTANCE_ID
SECURITY_GROUP_ID
LOG_GROUP_NAME
Step 18: Verify EventBridge Schedule

Navigate:

Amazon EventBridge
→ Rules

Expected:

rate(5 minutes)
Step 19: Test Auto Remediation

Recreate drift:

Open SSH to Internet
Add Port 8080
Change Environment Tag
Add ModifiedBy Tag
Step 20: Trigger Lambda Manually

Navigate:

Lambda
→ Test

Create Event:

{}

Run Test.

Step 21: Verify Remediation

Security Group should revert to:

22 → 10.0.0.0/8
80 → 10.0.0.0/8

Port 8080 removed.

EC2 Tags should revert to:

Environment = Production
ManagedBy = Terraform

Removed:

ModifiedBy
Step 22: Verify CloudWatch Logs

Navigate:

CloudWatch
→ Log Groups
→ /drift-detection/remediation

Expected Logs:

Drift Detected
Unauthorized Tags Removed
Security Group Restored
Remediation Complete
Step 23: Final Validation

Run:

terraform plan

Expected:

No changes.
Infrastructure matches configuration.

This confirms successful automated remediation.

🔄 End-to-End Workflow
Terraform Apply
        │
        ▼
Infrastructure Created
        │
        ▼
Manual Change
(Configuration Drift)
        │
        ▼
AWS Config
(NON_COMPLIANT)
        │
        ▼
EventBridge
(Every 5 Minutes)
        │
        ▼
Lambda
Detect → Remediate
        │
        ▼
CloudWatch Logs
        │
        ▼
Terraform Plan
(No Changes)
🎯 Key Outcomes

✅ Infrastructure as Code using Terraform

✅ Drift Detection using AWS Config

✅ Automated Remediation using Lambda

✅ Scheduled Monitoring using EventBridge

✅ Centralized Logging using CloudWatch

✅ Continuous Compliance Monitoring

✅ Automatic Recovery from Unauthorized Changes

🤝 Contributing

Fork the repository and create a feature branch for enhancements.

Open an issue before major changes and submit a pull request for review.

📜 License

This project is intended for educational, cloud automation, compliance monitoring, and Infrastructure as Code learning purposes.


This README follows the same rebuild-from-scratch style as the Blue-Green Deployment and ELK Stack projects and is based directly on all implementation phases in your Terraform Drift Detection project document. :contentReference[oaicite:1]{index=1}
