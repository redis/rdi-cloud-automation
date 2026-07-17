variable "identifier" {
  description = "Identifier used in resource names and propagated to db-shell as the deployment prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID. The bastion's security group lives here and is wired into each DB's SG as an ingress source."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion. Needs a route to the internet for apt/yum installs."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. t3.small is plenty for an interactive jump box."
  type        = string
  default     = "t3.small"
}

variable "ssh_password" {
  description = "Password for the shared `dev` user. Pass a random_password.result from the caller; do not hard-code."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks permitted to SSH to the bastion. Defaults to your office VPN egress in the caller."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region. Baked into the bastion's environment so db-shell.sh doesn't need to guess."
  type        = string
}

variable "update_scripts" {
  description = "Map of engine family name (mysql / postgres / sqlserver / oracle) -> SQL script content. Each is written to /opt/rdi-tools/updates/<name>.sql on the bastion and run by `make update-db <db>`."
  type        = map(string)
  default     = {}
}

variable "reset_scripts" {
  description = "Map of engine key (mysql / mariadb / postgres / sqlserver / oracle) -> initial-dataset SQL content. Each is written to /opt/rdi-tools/resets/<name>.sql on the bastion and run by `make reset-db <db>` to drop+reload the schema."
  type        = map(string)
  default     = {}
}
