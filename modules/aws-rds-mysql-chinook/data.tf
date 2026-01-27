# Needed for subnet creation
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest Aurora MySQL 8.0 engine version
data "aws_rds_engine_version" "mysql" {
  engine             = "aurora-mysql"
  version            = "8.0"
  include_all        = false
  default_only       = false
  latest             = true
}

