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
  validation {
    condition = var.redis_account != ""
    error_message = "The redis_account must be configured with your RDI account ID"
  }
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "azs" {
  type = list(string)
}
