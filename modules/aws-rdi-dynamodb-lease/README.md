# aws-rdi-dynamodb-lease

Creates the Amazon DynamoDB table that the RDI operator uses for its leader election lease
(`operator.leaderElection.leaseType: dynamodb`), plus an IAM policy with the permissions the
operator needs.

The table is a global table with multi-region strong consistency (MRSC), so the lease survives
the loss of any one region and two RDI instances in different regions fail over automatically. The
RDI operator refuses to start with an eventually consistent global table.

The table spans three regions:

- the region of the `aws` provider passed to the module, holding the first replica,
- `replica_region`, holding the second replica,
- `witness_region`, holding a DynamoDB managed witness that votes in the quorum but serves no
  traffic, holds no readable data, and is not billed.

Run one RDI instance in each replica region. All three regions must be in the same MRSC region set
(US, EU, or Asia Pacific).

## Usage

```hcl
provider "aws" {
  region = "eu-central-1"
}

module "rdi_lease" {
  source = "github.com/redis/rdi-cloud-automation//modules/aws-rdi-dynamodb-lease"

  table_name     = "rdi-lease"
  replica_region = "eu-west-2"
  witness_region = "eu-west-3"

  # Grant the operator access through an existing role (IRSA, EKS Pod Identity, instance profile)...
  attach_to_role_names = ["rdi-operator"]
  # ...or an IAM user whose access key goes into a shared credentials file.
  # attach_to_user_names = ["rdi-lease"]
}

output "rdi_helm_values" {
  value = module.rdi_lease.rdi_helm_values
}
```

Each entry of `rdi_helm_values` is the Helm values fragment for an RDI instance in that region.
Point every RDI instance at the replica in its own region.

The fragment covers only the lease store settings that come from this module. Each RDI instance
must also set its own, unique `operator.leaderElection.instanceID` in its RDI values: instances
left at the default `cluster-1` treat each other's lease as their own, and both become leader.

To manage IAM yourself, set `create_iam_policy = false` and use the `iam_policy_document` output.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `table_name` | `rdi-lease` | Table name, the same in every replica region. |
| `replica_region` | required | Region of the second replica, besides the provider region. |
| `witness_region` | required | Region of the witness. Must differ from both replica regions. |
| `deletion_protection_enabled` | `true` | Deletion protection on the table and each replica. |
| `create_iam_policy` | `true` | Create the IAM policy for the operator. |
| `iam_policy_name` | `<table_name>-dynamodb-lease` | IAM policy name. |
| `attach_to_role_names` | `[]` | Existing IAM roles to attach the policy to. |
| `attach_to_user_names` | `[]` | Existing IAM users to attach the policy to. |
| `tags` | `{}` | Tags for the table and the policy. |

## Outputs

`table_name`, `table_arn`, `table_arns` (both replica regions), `regions`, `iam_policy_arn`,
`iam_policy_document`, `rdi_helm_values` (per region).

## Notes

- Requires the `hashicorp/aws` provider `>= 6.22.0` (witness support). The other examples in this
  repository pin `~> 5.0`, so use this module from a root module on provider 6.x.
- The key schema (string partition key `id`) and the consistency mode cannot be changed after
  creation; changing `replica_region` or `witness_region` on an existing table may replace it. Since
  the lease is short-lived state, a replacement only causes a new leader election.
- For an HA pair within one region, the default `redsync` lease in the RDI database is usually
  enough and needs no DynamoDB table.
- Several RDI deployments can share one table with distinct `dynamoDBLease.keyName` values.
- The operator needs outbound HTTPS access to `dynamodb.<region>.amazonaws.com`.
