variable "region" {
  description = "AWS region for all resources."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile. Optional - falls back to AWS_PROFILE env var."
  type        = string
  default     = null
}

variable "name" {
  description = "Deployment name. Used as the VPC identifier."
  type        = string
}

variable "network" {
  description = "Shared VPC settings. One VPC is created and reused by every database."
  type = object({
    vpc_cidr = string
    azs      = list(string)
  })
}

variable "allowed_cidrs" {
  description = "Default CIDR list applied to every DB that doesn't set its own `allowed_cidrs`. Use this for your office VPN egress CIDR(s) so you only update one place. Per-DB `allowed_cidrs` overrides this; per-DB `allowed_cidrs = []` explicitly blocks all direct access."
  type        = list(string)
  default     = []
}

variable "databases" {
  description = <<-EOT
    Map of databases to deploy. The key becomes the identifier on every resource for that DB.
    Engine is required; everything else has a sensible default per engine.

    public_access = true makes the DB's NLB internet-facing and opens the DB port to allowed_cidrs.
    Defaults to false (PrivateLink only). Auto CDC user creation requires reachability via the NLB,
    so private-NLB deployments must run terraform from inside the VPC.

    allowed_cidrs - omitted = inherit the top-level `allowed_cidrs`; set explicitly (even `[]`)
                    to override (e.g. block all direct access on this one DB).

    redis_secrets_arn / redis_privatelink_arn - three states:
      - omitted (null): closed - no external principal can access this DB's secret / PrivateLink
      - "*"           : open   - any AWS principal can access
      - specific ARN  : scoped to that Redis Cloud subscription's principal
  EOT
  type = map(object({
    engine                = string
    port                  = optional(number)
    engine_version        = optional(string)
    instance_class        = optional(string)
    aurora_instance_count = optional(number, 1)
    public_access         = optional(bool, false)
    allowed_cidrs         = optional(list(string))
    redis_secrets_arn     = optional(string)
    redis_privatelink_arn = optional(string)
    database_name         = optional(string)
    init_sql_file         = optional(string)
  }))
}
