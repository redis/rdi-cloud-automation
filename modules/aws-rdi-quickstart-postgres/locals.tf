data "archive_file" "pg_docker" {
  type        = "tar.gz"
  source_dir  = "${path.module}/user-data"
  output_path = "userdata.tgz"
}

locals {
  az_map = zipmap(data.aws_availability_zones.available.zone_ids, data.aws_availability_zones.available.names)
  azs    = [for az_id in var.azs : local.az_map[az_id]]

  user_data = local.postgresql_user_data

  postgres_init_script = templatefile(
    "${path.module}/user-data/on-boot.sh",
    { db_password = var.db_password, db_port = var.db_port }
  )

  postgresql_user_data = <<-EOF
    Content-Type: multipart/mixed; boundary="//"
    MIME-Version: 1.0
     
    --//
    Content-Type: text/cloud-config; charset="us-ascii"
    MIME-Version: 1.0
    Content-Transfer-Encoding: 7bit
    Content-Disposition: attachment;
     filename="cloud-config.txt"
    #cloud-config
    write_files:
    - encoding: base64 
      content: ${filebase64(data.archive_file.pg_docker.output_path)} 
      path: /var/rdi-quickstart-postgres.tgz
      permissions: '0755'
    #cloud-config
    cloud_final_modules:
    - [scripts-user, always]
    - [write_files, always]
    --//
    Content-Type: text/x-shellscript; charset="us-ascii"
    MIME-Version: 1.0
    Content-Transfer-Encoding: 7bit
    Content-Disposition: attachment; filename="userdata.txt"
    ${local.postgres_init_script}
    --//--
EOF
}
