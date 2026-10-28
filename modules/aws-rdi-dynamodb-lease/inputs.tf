variable "table_name" {
  description = "Name of the DynamoDB lease table. The same name is used in every replica region."
  type        = string
  default     = "rdi-lease"
}

variable "replica_region" {
  description = "Region of the second replica of the lease table, besides the provider region. Run the second RDI instance in this region."
  type        = string
}

variable "witness_region" {
  description = "Region of the DynamoDB managed witness, the third vote of the quorum. It holds no readable data and needs no IAM permissions."
  type        = string
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection on the table and on each replica."
  type        = bool
  default     = true
}

variable "create_iam_policy" {
  description = "Create an IAM policy with the permissions the RDI operator needs on the lease table."
  type        = bool
  default     = true
}

variable "iam_policy_name" {
  description = "Name of the IAM policy. Defaults to \"<table_name>-dynamodb-lease\"."
  type        = string
  default     = null
}

variable "attach_to_role_names" {
  description = "Existing IAM role names (for example IRSA, EKS Pod Identity, or EC2 instance profile roles) to attach the policy to."
  type        = list(string)
  default     = []
}

variable "attach_to_user_names" {
  description = "Existing IAM user names to attach the policy to, when RDI uses a shared credentials file."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the table and the IAM policy."
  type        = map(string)
  default     = {}
}
