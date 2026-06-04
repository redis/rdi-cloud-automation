# How to use the multi-db example


## Using the bastion to connect to the source DB

1. SSH into the bastion
2. Run `make list` to list all the databases
3. Run `make sql-shell <db-name>` to connect to the database
4. Run `make reset-db <db-name>` to reset the database to the initial dataset
5. Run `make update-db <db-name>` to run the update script (CDC test mutations)

## Useful commands

### How to get the info for specific database

```
terraform output -json \
| jq '.databases.value["mysql-rds-01"] + {master_password: .db_passwords.value["mysql-rds-01"]}'
```
---

### How to get the info for the bastion

```
terraform output -json \
| jq '.bastion.value + {password: .bastion_password.value}'
```
---

### How to update a single source DB
```
terraform apply -target='module.db["mysql-aurora-01"]' -var-file=example.tfvars
```
