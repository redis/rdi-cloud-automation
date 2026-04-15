region                = "eu-central-1"
azs                   = ["euc1-az1", "euc1-az2", "euc1-az3"]
port                  = 5432
name                  = "redis-rdi-zdravko"
redis_secrets_arn     = "arn:aws:iam::148761665361:role/redis-data-pipeline-secrets-role"
redis_privatelink_arn = "arn:aws:iam::148761665361:role/redis-data-pipeline"
