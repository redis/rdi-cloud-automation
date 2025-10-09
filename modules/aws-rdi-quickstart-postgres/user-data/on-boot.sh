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

# # Add the PostgreSQL repository
# sudo amazon-linux-extras install postgresql13 -y

# # Install the PostgreSQL client
# sudo yum install postgresql -y

mkdir rdi-quickstart-postgres
cd rdi-quickstart-postgres/
tar xvf /var/rdi-quickstart-postgres.tgz
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/Chinook_PostgreSql.sql -o scripts/Chinook_PostgreSql.sql
curl https://raw.githubusercontent.com/Redislabs-Solution-Architects/rdi-quickstart-postgres/refs/heads/main/scripts/track.csv -o scripts/track.csv

# Build Docker PostgreSQL container
docker build -t postgres_rdi_ingest:v0.1 .

# Run Docker PostgreSQL container
docker run -d --rm --name postgres --rm -e POSTGRES_PASSWORD='${db_password}' -p ${db_port}:${db_port} postgres_rdi_ingest:v0.1
