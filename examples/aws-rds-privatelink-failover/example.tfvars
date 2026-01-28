region                = "eu-central-1"
azs                   = ["euc1-az1", "euc1-az2", "euc1-az3"]
port                  = 5432  # Use 5432 for postgres, 3306 for mysql
name                  = "rdi-rds-postgres-zdravko"
redis_secrets_arn     = ""
redis_privatelink_arn = ""
db_engine             = "postgres"  # Options: "postgres" or "mysql"
aws_profile           = "dev-rdi"