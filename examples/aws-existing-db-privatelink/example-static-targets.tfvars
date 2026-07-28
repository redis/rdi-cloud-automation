# Example: existing self-managed database or fixed target set.
#
# Use this mode only when the targets are stable or are maintained externally.
# For RDS/Aurora, prefer enable_rds_failover_lambda = true.

region      = "eu-central-1"
aws_profile = "default"
name        = "rdi-existing-static"

vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-abcdef0123456789a"]
db_port    = 1521

enable_rds_failover_lambda = false
target_type                = "ip"
static_targets = {
  db-1 = "10.0.101.25"
}

redis_privatelink_arn = "arn:aws:iam::123456789012:role/redis-data-pipeline"
redis_secrets_arn     = "arn:aws:iam::123456789012:role/redis-data-pipeline-secrets-role"

manage_security_group_rule = true
db_security_group_ids      = ["sg-0123456789abcdef0"]

create_secret = true
rdi_username  = "<put username here>"
rdi_password  = "<put password here>"

tags = {
  Project = "rdi"
}
