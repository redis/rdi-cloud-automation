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

variable "azs" {
  type = list(string)
}
