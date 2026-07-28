# Example: existing Aurora MySQL cluster.
#
# Replace every placeholder before applying. Values for redis_privatelink_arn
# and redis_secrets_arn come from the Redis Cloud RDI UI.

region      = "eu-central-1"
aws_profile = "default"
name        = "rdi-existing-mysql"

vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-abcdef0123456789a"]
db_port    = 3306

enable_rds_failover_lambda = true
rds_source_type            = "db-cluster"
rds_identifier             = "customer-aurora-mysql"

redis_privatelink_arn = "arn:aws:iam::123456789012:role/redis-data-pipeline"
redis_secrets_arn     = "arn:aws:iam::123456789012:role/redis-data-pipeline-secrets-role"

manage_security_group_rule = true
db_security_group_ids      = ["sg-0123456789abcdef0"]

create_secret = true
rdi_username  = "<put username here>" # e.g. debezium
rdi_password  = "<put password here>"

tags = {
  Project = "rdi"
}
