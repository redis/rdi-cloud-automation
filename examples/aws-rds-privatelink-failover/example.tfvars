region                = "us-east-1"
azs                   = ["use1-az2", "use1-az4", "use1-az6"]
port                  = 5432  # Use 5432 for postgres, 3306 for mysql
name                  = "rdi-rds"
redis_secrets_arn     = ""
redis_privatelink_arn = ""
db_engine             = "postgres"  # Options: "postgres" or "mysql"
