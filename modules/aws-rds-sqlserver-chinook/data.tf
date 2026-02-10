# Needed for subnet creation
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest SQL Server Standard Edition 2022 engine version
data "aws_rds_engine_version" "sqlserver" {
  engine       = "sqlserver-se"
  version      = "16.00"  # SQL Server 2022
  include_all  = false
  default_only = false
  latest       = true
}

