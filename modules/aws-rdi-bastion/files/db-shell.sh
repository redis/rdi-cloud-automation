#!/usr/bin/env bash
# Connect to one of the RDI source databases by short name.
# Environment expected (set by /etc/profile.d/rdi-tools.sh from user-data):
#   RDI_PREFIX         - deployment prefix (e.g. "rdi-ilian")
#   AWS_DEFAULT_REGION - region

# Source the env file if these aren't already set - covers non-login shells
# (e.g. when invoked from make in some terminals).
if [[ -z "${RDI_PREFIX:-}" || -z "${AWS_DEFAULT_REGION:-}" ]]; then
  # shellcheck source=/dev/null
  [[ -r /etc/profile.d/rdi-tools.sh ]] && source /etc/profile.d/rdi-tools.sh
fi

set -euo pipefail

: "${RDI_PREFIX:?RDI_PREFIX not set - source /etc/profile.d/rdi-tools.sh or run as a login shell}"
: "${AWS_DEFAULT_REGION:?AWS_DEFAULT_REGION not set}"

usage() {
  cat <<USAGE
Usage:
  db-shell.sh <db-name>           # open a SQL shell to the named DB
  db-shell.sh --info   <db-name>  # show endpoint / engine / RDI user (no password)
  db-shell.sh --update <db-name>  # run the engine-matched update script (CDC test mutations)
  db-shell.sh --reset  <db-name>  # drop + reload the schema from the initial dataset
  db-shell.sh --list              # list all DBs in this deployment
USAGE
}

UPDATES_DIR="/opt/rdi-tools/updates"
RESETS_DIR="/opt/rdi-tools/resets"

if [[ $# -eq 0 ]]; then
  usage; exit 1
fi

mode="shell"
case "$1" in
  --info)    mode="info";   shift ;;
  --update)  mode="update"; shift ;;
  --reset)   mode="reset";  shift ;;
  --list)    mode="list" ;;
  -h|--help) usage; exit 0 ;;
esac

cmd_list() {
  echo "Aurora clusters:"
  aws rds describe-db-clusters \
    --query "DBClusters[?starts_with(DBClusterIdentifier, 'aurora-${RDI_PREFIX}-')].DBClusterIdentifier" \
    --output text | tr '\t' '\n' | sed "s/^aurora-${RDI_PREFIX}-/  /"
  echo
  echo "Standalone RDS instances:"
  aws rds describe-db-instances \
    --query "DBInstances[?starts_with(DBInstanceIdentifier, 'rds-${RDI_PREFIX}-')].DBInstanceIdentifier" \
    --output text | tr '\t' '\n' | sed "s/^rds-${RDI_PREFIX}-/  /"
}

if [[ "$mode" == "list" ]]; then
  cmd_list
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "Missing db-name argument." >&2; usage; exit 1
fi

short="$1"
aurora_id="aurora-${RDI_PREFIX}-${short}"
rds_id="rds-${RDI_PREFIX}-${short}"

# Resolve engine + endpoint. Try Aurora cluster first, then standalone RDS instance.
engine=""
endpoint=""
port=""
database_name=""

if cluster_json=$(aws rds describe-db-clusters --db-cluster-identifier "$aurora_id" 2>/dev/null); then
  engine=$(echo "$cluster_json" | jq -r '.DBClusters[0].Engine')
  endpoint=$(echo "$cluster_json" | jq -r '.DBClusters[0].Endpoint')
  port=$(echo "$cluster_json" | jq -r '.DBClusters[0].Port')
  database_name=$(echo "$cluster_json" | jq -r '.DBClusters[0].DatabaseName // empty')
elif instance_json=$(aws rds describe-db-instances --db-instance-identifier "$rds_id" 2>/dev/null); then
  engine=$(echo "$instance_json" | jq -r '.DBInstances[0].Engine')
  endpoint=$(echo "$instance_json" | jq -r '.DBInstances[0].Endpoint.Address')
  port=$(echo "$instance_json" | jq -r '.DBInstances[0].Endpoint.Port')
  database_name=$(echo "$instance_json" | jq -r '.DBInstances[0].DBName // empty')
else
  echo "No Aurora cluster '$aurora_id' or RDS instance '$rds_id' found." >&2
  echo "Tip: run \`make list\` to see available DBs." >&2
  exit 1
fi

# SQL Server RDS does not expose DBName because the bundled initialization
# script creates `inventory` after instance creation. Other engines expose the
# configured database name (or Oracle SID) through the RDS API.
if [[ -z "$database_name" ]]; then
  case "$engine" in
    sqlserver-se|sqlserver-ex|sqlserver-web|sqlserver-ee) database_name="inventory" ;;
    *) echo "RDS did not return a database name for '$short' (engine=$engine)." >&2; exit 1 ;;
  esac
fi

# Find the Secrets Manager secret for this DB (name starts with "<prefix>-<short>-<random>").
secret_arn=$(aws secretsmanager list-secrets \
  --filter Key=name,Values="${RDI_PREFIX}-${short}-" \
  --query "SecretList[0].ARN" --output text 2>/dev/null || true)
if [[ -z "$secret_arn" || "$secret_arn" == "None" ]]; then
  echo "No Secrets Manager secret matching '${RDI_PREFIX}-${short}-*' found." >&2
  exit 1
fi

creds=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" --query SecretString --output text)
username=$(echo "$creds" | jq -r .username)
password=$(echo "$creds" | jq -r .password)

if [[ "$mode" == "info" ]]; then
  cat <<INFO
DB:        $short
engine:    $engine
endpoint:  $endpoint
port:      $port
database:  $database_name
user:      $username
secret:    $secret_arn
INFO
  exit 0
fi

# `family` picks the SQL dialect used by update scripts (mariadb shares MySQL).
# `reset_key` picks the initial-dataset filename (mariadb has its own due to collation).
case "$engine" in
  aurora-mysql)                                              family="mysql";     reset_key="mysql" ;;
  mysql)                                                     family="mysql";     reset_key="mysql" ;;
  mariadb)                                                   family="mysql";     reset_key="mariadb" ;;
  postgres|aurora-postgresql)                                family="postgres";  reset_key="postgres" ;;
  sqlserver-se|sqlserver-ex|sqlserver-web|sqlserver-ee)      family="sqlserver"; reset_key="sqlserver" ;;
  oracle-se2|oracle-ee|oracle-se1|oracle-se)                 family="oracle";    reset_key="oracle" ;;
  *) echo "Unknown engine: $engine" >&2; exit 1 ;;
esac

run_update() {
  local script="$UPDATES_DIR/$family.sql"
  if [[ ! -r "$script" ]]; then
    echo "Update script not found: $script" >&2
    exit 1
  fi
  echo "[$short] Running $script against engine=$engine ..."
  case "$family" in
    mysql)     MYSQL_PWD="$password" mysql -h "$endpoint" -P "$port" -u "$username" "$database_name" < "$script" ;;
    postgres)  PGPASSWORD="$password" psql -h "$endpoint" -p "$port" -U "$username" -d "$database_name" -v ON_ERROR_STOP=1 -f "$script" ;;
    sqlserver) sqlcmd -S "$endpoint,$port" -U "$username" -P "$password" -d "$database_name" -C -b -i "$script" ;;
    oracle)    sqlplus -L -S "$username/$password@$endpoint:$port/$database_name" @"$script" ;;
  esac
  echo "[$short] Update script complete."
}

run_shell() {
  case "$family" in
    mysql)     MYSQL_PWD="$password" mysql -h "$endpoint" -P "$port" -u "$username" "$database_name" ;;
    postgres)  PGPASSWORD="$password" psql -h "$endpoint" -p "$port" -U "$username" -d "$database_name" ;;
    sqlserver) sqlcmd -S "$endpoint,$port" -U "$username" -P "$password" -d "$database_name" -C ;;
    oracle)    sqlplus -L "$username/$password@$endpoint:$port/$database_name" ;;
  esac
}

# Reset uses the initial-dataset script which drops + recreates tables.
# For SQL Server / Oracle we connect as the master user because the reset
# DROP/CREATE statements need DDL privileges.
run_reset() {
  local script="$RESETS_DIR/$reset_key.sql"
  if [[ ! -r "$script" ]]; then
    echo "Reset script not found: $script" >&2
    exit 1
  fi

  # Master credentials live in terraform state, not on the bastion. We use
  # the RDI user for MySQL family (debezium has enough perms for table
  # operations on this schema) and the master where required. For SQL Server
  # and Oracle, the script was originally loaded by terraform as the master
  # user, so we may not have DDL via RDI user. Warn if that's the case.
  echo "[$short] Resetting from $script (engine=$engine)..."
  case "$family" in
    mysql)     MYSQL_PWD="$password" mysql -h "$endpoint" -P "$port" -u "$username" "$database_name" < "$script" ;;
    postgres)  PGPASSWORD="$password" psql -h "$endpoint" -p "$port" -U "$username" -d "$database_name" -v ON_ERROR_STOP=1 -f "$script" ;;
    sqlserver) sqlcmd -S "$endpoint,$port" -U "$username" -P "$password" -d master -C -b -i "$script" ;;
    oracle)    sqlplus -L -S "$username/$password@$endpoint:$port/$database_name" @"$script" ;;
  esac
  echo "[$short] Reset complete."
}

case "$mode" in
  update) run_update ;;
  reset)  run_reset ;;
  *)      run_shell ;;
esac
