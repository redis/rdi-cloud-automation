variable "identifier" {
  type        = string
  description = "A unique identifier for the resources created by this module"
}

variable "port" {
  type        = number
  description = "The port to listen on and forward to in the target group"
}

variable "targets" {
  type        = list(string)
  description = "The identifier of the load balancer targets - this can be an ip or EC2 instance ID"
}

variable "target_type" {
  type        = string
  description = "The type of load balancer target, this can be one of: ip, instance or lambda"
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "Must be one of \"instance\" or \"ip\" or \"lambda\""
  }
}

variable "acceptance_required" {
  type        = bool
  description = "Whether the PrivateLink Endpoint Service requires each new endpoint to be accepted"
  default     = false
}

variable "allowed_principals" {
  type        = list(string)
  description = "The list of AWS principals which can request an Endpoint for this Endpoint Service"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which to create the resources"
}

variable "subnets" {
  type        = list(string)
  description = "The list of subnets to create the resources in"
}

variable "security_groups" {
  type        = list(string)
  description = "The list of security groups to create the resources in"
}
