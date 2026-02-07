# Example configuration for SQL Server RDS deployment
# Copy this file and customize for your environment

# AWS Configuration
region      = "us-east-1"
aws_profile = null  # Set to your AWS CLI profile name, or use AWS_PROFILE env var

# Database Configuration
db_engine = "sqlserver"
port      = 1433  # Default SQL Server port
name      = "rdi-rds-sqlserver"

# Availability Zones (use zone IDs for your region)
# To get zone IDs: aws ec2 describe-availability-zones --region us-east-1
azs = ["use1-az2", "use1-az4", "use1-az6"]

# Redis Cloud Configuration
# Get these ARNs from the Redis Cloud console when setting up RDI
redis_secrets_arn     = "arn:aws:iam..."
redis_privatelink_arn = "arn:aws:iam..."

# RDS Proxy Configuration (DEPRECATED - not recommended for new deployments)
use_rds_proxy        = false
rds_proxy_require_tls = false

# Network Load Balancer Configuration
# Set to false for public NLB (testing only), true for private NLB (production)
nlb_internal = true

