#!/bin/bash

set -euo pipefail

DB_ENGINE=$(terraform output -raw database_engine)
DB_HOST=$(terraform output -raw db_host)
DB_USER=$(terraform output -raw database_username)
DB_PASS=$(terraform output -raw password)
DB_PORT=$(terraform output -raw port)
DB_NAME=$(terraform output -raw database)

if [ "$DB_ENGINE" == "postgres" ]; then
    echo "Connecting to PostgreSQL..."
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME"
elif [ "$DB_ENGINE" == "mysql" ]; then
    echo "Connecting to MySQL..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -P "$DB_PORT" "$DB_NAME"
else
    echo "Unknown database engine: $DB_ENGINE"
    exit 1
fi

