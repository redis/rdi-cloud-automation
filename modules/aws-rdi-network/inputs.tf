variable "identifier" {
  description = "Identifier suffix used in VPC resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the shared VPC. Must accommodate public + database subnets in each AZ."
  type        = string
}

variable "azs" {
  description = "Availability zone IDs (e.g. euc1-az1) to deploy into. Public + database subnets are created in each."
  type        = list(string)
}
