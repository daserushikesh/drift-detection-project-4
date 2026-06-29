# Infrastructure Drift Detection and Automated Remediation using Terraform & AWS Lambda

## Project Overview

This project demonstrates an automated Infrastructure Drift Detection and Remediation system on AWS using Terraform, AWS Config, AWS Lambda, Amazon EventBridge, and Amazon CloudWatch.

The infrastructure is provisioned using Terraform. If someone manually modifies AWS resources outside Terraform, AWS Config detects the drift, and an AWS Lambda function automatically restores the infrastructure back to the desired Terraform state.

---

# Architecture

```
                Terraform Apply
                       │
                       ▼
     EC2 + Security Group + S3 Bucket
                       │
                       ▼
      Manual Changes from AWS Console
                (Configuration Drift)
                       │
                       ▼
              AWS Config detects Drift
                       │
                       ▼
      EventBridge (Runs every 5 minutes)
                       │
                       ▼
             AWS Lambda Function
      Detect → Remediate → Log Actions
                       │
                       ▼
          CloudWatch Logs & Monitoring
                       │
                       ▼
      Terraform Plan → No Changes Found
```

---

# Technologies Used

* Terraform
* AWS EC2
* AWS Security Groups
* Amazon S3
* AWS Config
* AWS Lambda (Python 3.11)
* Amazon EventBridge
* Amazon CloudWatch
* IAM

---

# Project Structure

```
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
├── lambda/
│   └── remediation.py
│
└── README.md
```

---

# Prerequisites

Before starting, install the following tools.

## 1. Install Terraform

Verify installation

```bash
terraform -version
```

---

## 2. Install AWS CLI

Verify installation

```bash
aws --version
```

---

## 3. Configure AWS Credentials

```bash
aws configure
```

Enter

* AWS Access Key
* AWS Secret Key
* Region
* Output Format

Example

```
Region : us-east-1
Output : json
```

---

## 4. Install VS Code

Recommended Extensions

* Terraform
* Python
* AWS Toolkit

---

# Step 1 – Clone the Repository

```bash
git clone https://github.com/<your-username>/drift-detection-project.git

cd drift-detection-project
```

---

# Step 2 – Initialize Terraform

Navigate to the terraform directory.

```bash
cd terraform
```

Initialize Terraform.

```bash
terraform init
```

---

# Step 3 – Validate Configuration

```bash
terraform validate
```

Expected Output

```
Success! The configuration is valid.
```

---

# Step 4 – Preview Infrastructure

```bash
terraform plan
```

Terraform displays all resources that will be created.

---

# Step 5 – Deploy Infrastructure

```bash
terraform apply
```

Type

```
yes
```

Terraform creates

* EC2 Instance
* Security Group
* S3 Bucket
* AWS Config
* Lambda
* EventBridge
* IAM Roles
* CloudWatch Log Group

---

# Step 6 – Verify Resources

Open AWS Console.

Verify

### EC2

* Running

### Security Group

Inbound Rules

* Port 22
* Port 80

Allowed CIDR

```
10.0.0.0/8
```

### S3

Verify

* Versioning Enabled
* Server-side Encryption Enabled

---

# Step 7 – Simulate Infrastructure Drift

Open AWS Console.

## Security Group Drift

Modify

SSH Rule

```
10.0.0.0/8
```

to

```
0.0.0.0/0
```

Add another inbound rule

```
Port 8080
Source 0.0.0.0/0
```

---

## EC2 Tag Drift

Change

```
Environment = Production
```

to

```
Environment = Development
```

Add

```
ModifiedBy = ManualChange
```

---

# Step 8 – Detect Drift

Run

```bash
terraform plan
```

Terraform should detect differences between the deployed infrastructure and the desired state.

AWS Config also marks the resources as

```
NON_COMPLIANT
```

---

# Step 9 – Lambda Auto Remediation

Lambda automatically performs the following actions

* Removes unauthorized tags
* Restores required tags
* Removes unauthorized Security Group rules
* Restores approved inbound rules
* Writes logs to CloudWatch

---

# Step 10 – Test Auto Remediation

Instead of waiting for EventBridge,

Open

```
AWS Lambda
```

Select

```
drift-detection-remediation
```

Create a Test Event

```json
{}
```

Click

```
Test
```

---

# Step 11 – Verify Remediation

Check

### EC2 Tags

```
Environment = Production
ManagedBy = Terraform
```

Removed

```
ModifiedBy
```

---

### Security Group

Only these rules should remain

```
22 → 10.0.0.0/8

80 → 10.0.0.0/8
```

Port

```
8080
```

should be removed.

---

### CloudWatch

Verify logs showing

* Drift detected
* Resources remediated
* Successful execution

---

# Final Verification

Run

```bash
terraform plan
```

Expected Output

```
No changes.

Infrastructure matches the Terraform configuration.
```

---

# Cleanup

Destroy all AWS resources

```bash
terraform destroy
```

Type

```
yes
```

---

# Key Features

* Infrastructure as Code using Terraform
* Automated Drift Detection
* AWS Config Compliance Rules
* Automatic Infrastructure Remediation
* CloudWatch Logging
* EventBridge Scheduling
* Fully Automated AWS Infrastructure Management

---

# Author

**Rushikesh Dase**

Cloud & DevOps Engineer

GitHub: [https://github.com/<your-username>](https://github.com/daserushikesh)

LinkedIn: www.linkedin.com/in/rushi-dase
