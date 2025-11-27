#!/bin/bash

set -euo pipefail

psql "postgresql://postgres:$(terraform output -raw password)@$(terraform output -raw psql_host)/chinook"
