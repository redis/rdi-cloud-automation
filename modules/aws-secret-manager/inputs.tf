variable "identifier" {
  type = string
}

variable "redis_account" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}
