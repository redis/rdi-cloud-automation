output "vpc_id" {
  description = "Shared VPC ID."
  value       = module.network.vpc_id
}

output "db_passwords" {
  description = "Master passwords keyed by DB identifier. Sensitive - use `terraform output -json db_passwords` or `-raw` to read."
  sensitive   = true
  value       = { for key, _ in var.databases : key => random_password.db[key].result }
}

output "bastion" {
  description = "Bastion connection details (null when bastion.enabled = false). SSH password is in the sensitive `bastion_password` output."
  value = var.bastion.enabled ? {
    host        = module.bastion[0].public_dns
    public_ip   = module.bastion[0].public_ip
    user        = module.bastion[0].ssh_user
    instance_id = module.bastion[0].instance_id
  } : null
}

output "bastion_password" {
  description = "SSH password for the bastion's `dev` user. Sensitive - read via `terraform output -raw bastion_password`."
  sensitive   = true
  value       = var.bastion.enabled ? random_password.bastion[0].result : null
}

output "databases" {
  description = "Per-DB connection details. Paste secret_arn and vpc_endpoint_service_name into Redis Cloud RDI for each source."
  value = {
    for key, db in module.db : key => {
      engine                    = db.engine
      endpoint                  = db.endpoint
      port                      = db.port
      rdi_username              = db.rdi_username
      secret_arn                = db.secret_arn
      vpc_endpoint_service_name = db.vpc_endpoint_service_name
      nlb_hostname              = db.nlb_hostname
    }
  }
}
