region                = ""
source_db_mode        = "existing"
port                  = 5432 # Use 5432 for postgres, 3306 for mysql
name                  = ""
redis_secrets_arn     = ""
redis_privatelink_arn = ""
db_engine             = "postgres" # Options: "postgres" or "mysql"
aws_profile           = null
use_rds_proxy         = false # Deprecated; keep the direct NLB + Lambda path for existing databases.

# Keep the NLB internal for PrivateLink-only access. Set to false only when
# direct public testing is explicitly needed.
nlb_internal = true

# Optional. Leave empty for PrivateLink-only access. If nlb_internal = false,
# add your trusted public CIDR blocks here for direct NLB testing.
nlb_ingress_cidr_blocks = []

# If true, Terraform adds ingress rules to existing_db.db_security_group_ids
# allowing the generated NLB security group to reach the source database port.
# If false, add the DB security group rule manually after apply using the
# existing_db_nlb_security_group_id output.
manage_existing_db_security_group_ingress = false

existing_db = {
  hostname              = ""
  username              = ""
  database              = ""
  vpc_id                = ""
  subnet_ids            = []
  db_security_group_ids = []
  rds_event_source_id   = ""
  rds_event_source_type = "db-cluster" # Options: "db-cluster" or "db-instance"
}

# Prefer passing this as a CLI/env var for real usage:
# terraform apply -var-file example-existing-db.tfvars -var 'existing_db_password=...'
existing_db_password = ""
