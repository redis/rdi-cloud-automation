#!/bin/bash

set -euo pipefail

psql "postgresql://$(terraform output -raw rdi_username):$(terraform output -raw rdi_password)@$(terraform output -raw db_host):$(terraform output -raw port)/$(terraform output -raw database)"
