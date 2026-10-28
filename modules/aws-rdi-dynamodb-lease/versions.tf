terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.22.0 added global_table_witness; replica.consistency_mode is 6.x only.
      version = ">= 6.22.0"
    }
  }
  required_version = ">= 1.5.0"
}
