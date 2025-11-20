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
  type        = string
}

variable "rds_arn" {
  type        = string
}
