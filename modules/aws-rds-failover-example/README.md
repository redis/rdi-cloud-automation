# AWS Lambda, SNS, RDS Aurora PostgreSQL, and CloudWatch Events Module

This Terraform module provisions the following AWS resources:

- **AWS Lambda Function** - Serverless compute with CloudWatch logs
- **AWS SNS Topic** - Pub/sub messaging service
- **AWS RDS Aurora PostgreSQL** - Managed relational database cluster
- **AWS CloudWatch Event Rule** - Scheduled trigger for the Lambda function

## Architecture

The module creates the following infrastructure:

1. A Lambda function with execution role and necessary IAM permissions
2. An SNS topic that the Lambda can publish to
3. An RDS Aurora PostgreSQL cluster with a cluster instance
4. A CloudWatch Event rule that schedules the Lambda function to run
5. Security groups, IAM roles, and networking resources

## Usage

### Basic Example

```h Terraform
module "lambda_sns_rds_cloudwatch" {
  source = "../../modules/aws-lambda-sns-rds-cloudwatch"

  identifier = "my-app"
  environment = "dev"

  # Lambda configuration
  lambda_function_name = "my-lambda-function"
  lambda_source_path   = "./lambda_function.zip"
  lambda_handler       = "index.handler"
  lambda_runtime       = "python3.11"

  # SNS configuration
  sns_topic_name = "my-sns-topic"

  # RDS configuration
  db_instance_class = "db.t3.medium"
  db_engine_version = "15.3"
  db_master_username = "postgres"
  db_master_password = "your-secure-password-here"

  # Networking
  vpc_id     = "vpc-xxxxxxxxx"
  subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]

  # CloudWatch Events
  cloudwatch_schedule_expression = "rate(1 hour)"
}
```

### Advanced Example

```hcl
module "lambda_sns_rds_cloudwatch" {
  source = "../../modules/aws-lambda-sns-rds-cloudwatch"

  identifier = "production-app"
  environment = "prod"

  # Lambda configuration
  lambda_function_name = "data-processor"
  lambda_source_path   = "./lambda_code.zip"
  lambda_handler       = "handler.process"
  lambda_runtime       = "python3.11"
  lambda_timeout      = 60
  lambda_memory_size  = 256
  lambda_environment_variables = {
    LOG_LEVEL = "INFO"
    MAX_RETRIES = "3"
  }

  # SNS configuration
  sns_topic_name   = "data-processing-notifications"
  sns_display_name = "Data Processing Notifications"

  # RDS Aurora configuration
  db_instance_class       = "db.r6g.large"
  db_engine_version       = "15.3"
  db_master_username      = "admin"
  db_master_password      = var.db_password
  db_name                 = "production_db"
  backup_retention_period  = 14
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Networking
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  # Security
  allowed_security_group_ids = [
    aws_security_group.app.id,
    aws_security_group.admin.id
  ]

  # CloudWatch Events
  cloudwatch_schedule_expression = "cron(0 12 * * ? *)"  # Daily at noon UTC
  enabled = true

  # Tags
  tags = {
    Project     = "data-processing"
    Team        = "engineering"
    CostCenter  = "12345"
  }
}
```

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0
- Existing VPC and subnets
- Lambda function code packaged as a ZIP file

## Resources Created

### Lambda
- Lambda function with CloudWatch logs
- IAM execution role
- CloudWatch log group
- Permissions for SNS and RDS access

### SNS
- SNS topic

### RDS Aurora
- RDS Aurora PostgreSQL cluster
- RDS cluster instance
- DB subnet group
- Security group
- Enhanced monitoring role

### CloudWatch Events
- CloudWatch Event rule
- Event target linking rule to Lambda
- Lambda permission for CloudWatch Events

## Outputs

- `lambda_function_arn` - ARN of the Lambda function
- `lambda_function_name` - Name of the Lambda function
- `lambda_invoke_arn` - ARN to invoke the Lambda function
- `sns_topic_arn` - ARN of the SNS topic
- `sns_topic_name` - Name of the SNS topic
- `rds_cluster_endpoint` - RDS Aurora cluster endpoint
- `rds_cluster_reader_endpoint` - RDS Aurora cluster reader endpoint
- `rds_cluster_id` - RDS Aurora cluster ID
- `rds_cluster_arn` - RDS Aurora cluster ARN
- `cloudwatch_event_rule_arn` - ARN of the CloudWatch Event rule
- `cloudwatch_event_rule_name` - Name of the CloudWatch Event rule
- `lambda_execution_role_arn` - ARN of the Lambda execution role
- `lambda_log_group_name` - Name of the CloudWatch Log Group for Lambda

## Security Considerations

1. **Database Password**: Use AWS Secrets Manager or a secure vault to store the master password
2. **Security Groups**: Review and adjust the security group rules based on your requirements
3. **IAM Roles**: The Lambda execution role has permissions to publish to SNS and read RDS metadata
4. **VPC Configuration**: Ensure subnets are properly configured for RDS
5. **Backup Settings**: Configure appropriate backup retention periods for production

## Lambda Function Integration

The Lambda function will receive the following environment variables:
- `SNS_TOPIC_ARN` - ARN of the SNS topic
- `DB_ENDPOINT` - RDS cluster endpoint
- `DB_NAME` - Database name

### Example Lambda Function

```python
import os
import boto3
import psycopg2

sns = boto3.client('sns')

def handler(event, context):
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    db_endpoint = os.environ['DB_ENDPOINT']
    db_name = os.environ['DB_NAME']
    
    # Your database operations here
    # conn = psycopg2.connect(...)
    
    message = f"Lambda executed successfully at {context.request_id}"
    
    sns.publish(
        TopicArn=sns_topic_arn,
        Message=message,
        Subject="Lambda Execution Notification"
    )
    
    return {"statusCode": 200, "body": "Success"}
```

## Variables Reference

See `inputs.tf` for a complete list of available variables.

## Notes

- The Lambda function is automatically triggered by the CloudWatch Event rule
- The RDS cluster is created in private subnets within the specified VPC
- Security groups are configured to allow database access from specified security groups
- Consider using AWS Systems Manager Parameter Store or Secrets Manager for sensitive data

