#!/bin/bash

set -euo pipefail

psql "postgresql://postgres:$(terraform output -raw password)@$(terraform output -raw ec2_instance_hostname)/chinook"
