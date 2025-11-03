variable "identifier" {
  type = string
}

variable "allowed_principals" {
  type = list(string)
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}
