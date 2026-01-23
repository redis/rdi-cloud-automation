# rdi-cloud-automation

![Secret Scanning](https://github.com/redis/rdi-cloud-automation/actions/workflows/secret-scan.yml/badge.svg)

Terraform modules to configure producer databases and network connectivity for RDI.

## Examples

The `examples` directory contains complete examples which can be configured and run with `terraform apply`:

### aws-ec2-privatelink

Creates an example Postgres database exposed with PrivateLink. This example creates a VPC and can be used to try RDI quickly with no existing resources. 

### aws-rds-privatelink-failover

Creates an Aurora RDS database with two instances exposed with PrivateLink. This example supports failing over between instances using a Lambda function to detect events. 

## Modules

The `modules` directory contains reusable Terraform modules which can be composed together.

### aws-privatelink

AWS PrivateLink connection via a Network Load Balancer.

### aws-rdi-quickstart-postgres

VPC and EC2 instance with a sample Postgres database.

### aws-rds-chinook

Aurora Postgres RDS cluster with 2 instances.

### aws-rds-lambda

A Lambda function triggered by RDS Events to SNS, which updates an NLB with the current Aurora writer instance.

### aws-secret-manager

AWS KMS Key and Secret Manager secret for RDI to authenticate.

## 🔒 Security

This repository uses automated secret scanning to prevent accidental credential leaks:

- **Gitleaks** - Fast regex-based secret detection
- **TruffleHog** - High-entropy string detection with verification
- **detect-secrets** - Baseline-based secret scanning

Secret scanning runs automatically on:
- Every push to main branches
- Every pull request
- Weekly scheduled scans

For more information, see:
- [Security Policy](.github/SECURITY.md)
- [Secret Scanning Guide](.github/SECRET_SCANNING.md)

### Quick Start - Local Scanning

```bash
# Install Gitleaks
brew install gitleaks  # macOS

# Scan before committing
gitleaks detect --no-git

# Install pre-commit hook
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/pre-commit.py -o .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
