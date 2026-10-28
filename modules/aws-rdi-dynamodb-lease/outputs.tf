output "table_name" {
  value = aws_dynamodb_table.lease.name
}

output "table_arn" {
  description = "ARN of the table in the provider region."
  value       = aws_dynamodb_table.lease.arn
}

output "table_arns" {
  description = "ARNs of the table in every replica region."
  value       = local.table_arns
}

output "regions" {
  description = "Regions holding a replica of the lease table. Point each RDI instance at the region it runs in."
  value       = local.replica_regions
}

output "iam_policy_document" {
  description = "Policy JSON with the permissions RDI needs, for use when create_iam_policy = false."
  value       = data.aws_iam_policy_document.lease.json
}

output "iam_policy_arn" {
  value = var.create_iam_policy ? aws_iam_policy.lease[0].arn : null
}

output "rdi_helm_values" {
  description = "RDI Helm values for the lease store, per region. Covers only the settings from this module: set a unique operator.leaderElection.instanceID for each RDI instance in its own values."
  value = {
    for region in local.replica_regions : region => yamlencode({
      operator = {
        leaderElection = {
          enabled   = true
          leaseType = "dynamodb"
          dynamoDBLease = {
            region    = region
            tableName = aws_dynamodb_table.lease.name
          }
        }
      }
    })
  }
}
