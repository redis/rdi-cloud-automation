#!/bin/bash

set -euo pipefail

mysql \
  -h "$(terraform output -raw db_host)" \
  -u "$(terraform output -raw rdi_username)" \
  -p"$(terraform output -raw rdi_password)" \
  -P "$(terraform output -raw port)" \
  "$(terraform output -raw database)"
