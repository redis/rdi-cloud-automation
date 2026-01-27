#!/bin/bash

set -euo pipefail

psql "postgresql://$(terraform output -raw database_username):$(terraform output -raw password)@$(terraform output -raw db_host)/chinook"
