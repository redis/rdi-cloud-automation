#!/bin/bash

set -euo pipefail

mysql -h "$(terraform output -raw db_host)" -u "$(terraform output -raw database_username)" -p"$(terraform output -raw password)" -P "$(terraform output -raw port)" chinook

