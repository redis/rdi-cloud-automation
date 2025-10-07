data "archive_file" "pg_docker" {
  type = "tar.gz"
  source_dir = "${path.module}/user-data"
  output_path = "userdata.tgz"
}

locals {
  az_map = zipmap(data.aws_availability_zones.available.zone_ids, data.aws_availability_zones.available.names)
  azs    = [for az_id in var.azs : local.az_map[az_id]]

  user_data = (
    var.db_type == "sqlserver" ? local.sqlserver_user_data :
    var.db_type == "oracle" ? local.oracle_user_data :
    var.db_type == "mysql" ? local.mysql_user_data :
    var.db_type == "mariadb" ? local.mariadb_user_data :
    local.postgresql_user_data
  )

  postgres_init_script = templatefile(
    "${path.module}/user-data/on-boot.sh",
    {db_password = var.db_password, db_port = var.db_port}
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

  oracle_user_data = <<-EOF
    #!/bin/bash
    # Update the system
    sudo apt-get update

    # Install Docker
    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Add current user to the Docker group
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    newgrp docker

    # Download and load the Oracle database image
    wget https://rdi-public.s3.us-east-1.amazonaws.com/ora19c-x86.tar
    docker load -i ora19c-x86.tar
  
    # Clone the Oracle repository 
    git clone https://github.com/Redislabs-Solution-Architects/rdi-quickstart-oracle.git

    # Set up the .env file and set user and password for the Oracle LogMiner user script
    cd rdi-quickstart-oracle
    
    # Set up the .env file based on TLS configuration
    if [ "${var.source_db_tls_enabled}" = "true" ]; then
      sed -e "s/#ENABLE_TCPS=true/ENABLE_TCPS=true/g" env.oracle > .env
    else
      cp env.oracle .env
    fi
    
    source .env
    sudo sed -e "s/<DBZUSER>/$DBZUSER/g" -e "s/<DBZUSER_PASSWORD>/$DBZUSER_PASSWORD/g" templates/04-Logminer_User.template > sql/04-Logminer_User.sql
    sudo chmod -R 777 oradata

    # Run the container and bind mount ordata directory
    docker run --name ora19c --env-file .env -v $PWD/oradata:/opt/oracle/oradata -v $PWD/sql:/docker-entrypoint-initdb.d/setup -p ${var.db_port}:${var.db_port} -p 5500:5500 -e ORACLE_PDB=${var.source_pdb} -d oracle/database:19.3.0-ee
  EOF

  sqlserver_user_data = <<-EOF
    #!/bin/bash
    # Update the system
    sudo apt-get update

    # Install Docker
    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Add current user to the Docker group
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    newgrp docker

    # Clone the repository with the SQL Server data
    sudo git clone https://github.com/Redislabs-Solution-Architects/rdi-quickstart-sqlserver.git

    # Change to the directory with the SQL Server data
    cd rdi-quickstart-sqlserver/

    # Build Docker SQL Server container
    docker build -t sqlserver sqlserver-image

    # Copy env settings with users setup and give permissions to the data and log directories
    sudo cp env.sqlserver .env
    sudo chmod -R 777 data
    sudo chmod -R 777 log

    # Run Docker SQL Server container
    docker run --name sqlserver --env-file .env -v $PWD/data:/var/opt/mssql/data -v $PWD/log:/var/opt/mssql/log -p ${var.db_port}:${var.db_port} -d sqlserver
  EOF

  mysql_user_data = <<-EOF
    #!/bin/bash
    # Update the system
    sudo apt-get update

    # Install Docker
    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Add current user to the Docker group
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    newgrp docker

    # Clone the repository with the MySQL data
    sudo git clone https://github.com/vhristev-1/chinook-database.git

    # Change to the directory with the MySQL data
    cd chinook-database/

    # Build Docker MySQL container
    MYSQL_PORT=${var.db_port} docker compose -f docker-compose.yml create mysql
    
    # Run Docker MySQL container
    docker start mysql
  EOF

  mariadb_user_data = <<-EOF
    #!/bin/bash
    # Update the system
    sudo apt-get update

    # Install Docker
    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    # Add current user to the Docker group
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    newgrp docker

    # Clone the repository with the SQL Server data
    sudo git clone https://github.com/vhristev-1/chinook-database.git

    # Change to the directory with the SQL Server data
    cd chinook-database/

    # Build Docker SQL Server container
    MARIA_DB_PORT=${var.db_port} docker compose -f docker-compose.yml create mariadb
    
    # Run Docker SQL Server container
    docker start mariadb
  EOF
}
