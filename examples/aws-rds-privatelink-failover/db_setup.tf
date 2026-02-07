# Commented out: This requires network access to the private RDS instance
# To set up the database, either:
# 1. Run the psql.sh script from a bastion host or machine with VPC access
# 2. Use AWS Systems Manager Session Manager to connect to an EC2 instance in the VPC
# 3. Set up a VPN connection to the VPC
#
# resource "null_resource" "setup_chinook_postgres" {
#   count = var.db_engine == "postgres" ? 1 : 0
#   depends_on = [
#     module.rdi_quickstart_postgres,
#     module.rds_lambda
#   ]
#   provisioner "local-exec" {
#     environment = {
#       PGPASSWORD : nonsensitive(random_password.db_password.result)
#     }
#     command = <<EOF
# #!/bin/sh
# set -x
# mkdir -p scripts
# curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/Chinook_PostgreSql.sql -o scripts/Chinook_PostgreSql.sql
# curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/track.csv -o scripts/track.csv
# psql -h ${module.privatelink.lb_hostname} -d chinook -U postgres -p ${var.port} -f scripts/Chinook_PostgreSql.sql > postgres_setup.log
# EOF
#   }
# }

# NOTE: The debezium user is now automatically created in main.tf via the
# create_mysql_debezium_user resource. This happens automatically during terraform apply.
#
# Commented out: Optional Chinook sample database setup
# This requires network access to the RDS instance (nlb_internal = false or VPN/bastion)
# To load the Chinook sample database, either:
# 1. Uncomment this resource and run terraform apply (if nlb_internal = false)
# 2. Run the mysql.sh script manually from a bastion host or machine with VPC access
# 3. Use AWS Systems Manager Session Manager to connect to an EC2 instance in the VPC
#
# resource "null_resource" "setup_chinook_mysql" {
#   count = var.db_engine == "mysql" ? 1 : 0
#   depends_on = [
#     module.rdi_quickstart_mysql,
#     module.privatelink,
#     null_resource.create_mysql_debezium_user  # Wait for debezium user to be created first
#   ]
#   provisioner "local-exec" {
#     environment = {
#       MYSQL_PWD : nonsensitive(random_password.db_password.result)
#     }
#     command = <<EOF
# #!/bin/sh
# set -e
# mkdir -p scripts
#
# # Download and load Chinook sample database
# echo "Downloading Chinook MySQL database..."
# curl https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_MySql.sql -o scripts/Chinook_MySql.sql
#
# echo "Loading Chinook database into MySQL..."
# mysql -h ${module.privatelink.lb_hostname} -u admin -P ${var.port} chinook < scripts/Chinook_MySql.sql > mysql_setup.log 2>&1
#
# echo "Chinook database loaded successfully!"
# EOF
#   }
# }
