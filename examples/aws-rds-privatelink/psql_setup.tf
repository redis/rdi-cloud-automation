resource "null_resource" "setup_chinook" {
  depends_on = [ 
    module.rdi_quickstart_postgres  
  ]
  provisioner "local-exec" {
    environment = {
      PGPASSWORD: nonsensitive(random_password.pg_password.result)
    }
    command = <<EOF
#!/bin/sh
set -x
mkdir scripts
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/Chinook_PostgreSql.sql -o scripts/Chinook_PostgreSql.sql
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/track.csv -o scripts/track.csv
psql -h ${module.privatelink.lb_hostname} -d chinook -U postgres -p ${var.port} -f scripts/Chinook_PostgreSql.sql > mysql.log
EOF
  }
}
