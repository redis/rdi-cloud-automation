variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/20"
}

variable "azs" {
  description = "A list of availability zones to deploy the EKS cluster into"
  type        = list(string)
  default     = ["use1-az2", "use1-az4", "use1-az6"]
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "instance_type" {
  description = "The type of the EC2 instance"
  type        = string
  default     = "t2.2xlarge"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair in AWS"
  type        = string
}

variable "identifier" {
  description = "The identifier for the resources/test"
  type        = string
}

variable "db_type" {
  description = "The type of database"
  type        = string
  validation {
    condition     = contains(["postgresql", "oracle", "sqlserver", "mariadb", "mysql"], var.db_type)
    error_message = "Invalid source_type, valid options are: postgresql, oracle, sqlserver, mariadb, mysql"
  }
}

variable "db_password" {
  description = "The password for connecting to the Producer Source Database"
  type        = string
}

variable "db_port" {
  description = "The port for connecting to the Producer Source Database"
  type        = number
}

variable "source_pdb" {
  description = "Related to Oracle source type. The pluggable database to replicate"
  type        = string
  default     = "ORCLPDB1"
}

variable "source_db_tls_enabled" {
  description = "Whether the source database requires TLS for connections"
  type        = bool
  default     = false
}

