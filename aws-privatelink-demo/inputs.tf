variable "region" {
  type = string
}

variable "port" {
  type = number
}

variable "name" {
  type = string
}

variable "redis_account" {
  type = string
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "azs" {
  type = list(string)
}
