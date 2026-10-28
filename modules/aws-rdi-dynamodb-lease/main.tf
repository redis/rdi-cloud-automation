data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  primary_region = data.aws_region.current.region
  # Regions holding a copy of the lease. The witness serves no traffic.
  replica_regions = [local.primary_region, var.replica_region]

  table_arns = [
    for region in local.replica_regions :
    "arn:${data.aws_partition.current.partition}:dynamodb:${region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
  ]
}

# A global table with multi-region strong consistency (MRSC) across two replicas and a witness, so
# the lease survives the loss of any one region. The RDI operator requires a single string partition
# key named "id", and refuses to start with an eventually consistent global table. Both the key
# schema and the consistency mode are fixed at creation, so changing them replaces the table.
resource "aws_dynamodb_table" "lease" {
  name                        = var.table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "id"
  deletion_protection_enabled = var.deletion_protection_enabled

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name                 = var.replica_region
    consistency_mode            = "STRONG"
    deletion_protection_enabled = var.deletion_protection_enabled
  }

  global_table_witness {
    region_name = var.witness_region
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(distinct([local.primary_region, var.replica_region, var.witness_region])) == 3
      error_message = "The provider region, replica_region, and witness_region must all be different."
    }
  }
}
