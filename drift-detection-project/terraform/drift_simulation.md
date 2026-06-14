# Drift Simulation Documentation

## Date: (today's date)

## Change 1: Security Group Rule Modified
- Resource: drift-detection-sg (sg-00a13dca8dd7241e9)
- What changed: 
  - SSH port 22 source changed from 10.0.0.0/8 to 0.0.0.0/0
  - New rule added: Port 8080 from 0.0.0.0/0
- Who changed: Manual change via AWS Console
- Risk: Critical - SSH open to entire internet

## Change 2: EC2 Tag Modified  
- Resource: drift-detection-ec2 (i-0835d5e72063b4fab)
- What changed:
  - Environment tag: Production → Development
  - New tag added: ModifiedBy = ManualChange
- Who changed: Manual change via AWS Console
- Risk: Medium - Incorrect environment classification

## Impact:
- Infrastructure no longer matches Terraform state
- Security vulnerability introduced
- Audit trail broken
