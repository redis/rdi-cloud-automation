#!/bin/bash

set -e

PGDATA="${PGDATA:-/var/lib/postgresql/data}"

echo "wal_level = logical" >> $PGDATA/postgresql.conf

psql -U postgres postgres -f ~/chinook_create.sql
psql -U postgres chinook -f ~/Chinook_PostgreSql.sql
