resource "null_resource" "setup_chinook_postgres" {
  count = var.db_engine == "postgres" ? 1 : 0
  depends_on = [
    module.rdi_quickstart_postgres,
    module.rds_lambda
  ]
  provisioner "local-exec" {
    environment = {
      PGPASSWORD : nonsensitive(random_password.db_password.result)
    }
    command = <<EOF
#!/bin/sh
set -x
mkdir -p scripts
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/Chinook_PostgreSql.sql -o scripts/Chinook_PostgreSql.sql
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/track.csv -o scripts/track.csv
psql -h ${module.privatelink.lb_hostname} -d chinook -U postgres -p ${var.port} -f scripts/Chinook_PostgreSql.sql > postgres_setup.log
EOF
  }
}

resource "null_resource" "setup_chinook_mysql" {
  count = var.db_engine == "mysql" ? 1 : 0
  depends_on = [
    module.rdi_quickstart_mysql,
    module.rds_lambda
  ]
  provisioner "local-exec" {
    environment = {
      MYSQL_PWD : nonsensitive(random_password.db_password.result)
    }
    command = <<EOF
#!/bin/sh
set -x
mkdir -p scripts

# Download and load Chinook database
curl https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_MySql.sql -o scripts/Chinook_MySql.sql
mysql -h ${module.privatelink.lb_hostname} -u admin -P ${var.port} chinook < scripts/Chinook_MySql.sql > mysql_setup.log 2>&1

# Create Debezium user for RDI with required grants
mysql -h ${module.privatelink.lb_hostname} -u admin -P ${var.port} -e "
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY '${random_password.debezium_password.result}';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT, LOCK TABLES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
" >> mysql_setup.log 2>&1

echo "Debezium user created successfully"
EOF
  }
}
