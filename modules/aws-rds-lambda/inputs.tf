variable "identifier" {
  description = "The identifier for the resources/test"
  type        = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type = number
}

variable "elb_tg_arn" {
  type = string
}

variable "rds_arn" {
  type = string
}

variable "rds_cluster_identifier" {
  description = "The RDS cluster identifier for event subscription (always points to RDS, not proxy)"
  type        = string
}
