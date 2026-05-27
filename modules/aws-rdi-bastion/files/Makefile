.PHONY: sql-shell update-db reset-db info list help

# Usage:
#   make sql-shell <db-name>   - open a SQL shell to the named DB
#   make update-db <db-name>   - run engine-matched update script (CDC test mutations)
#   make reset-db <db-name>    - drop + reload schema from the initial dataset
#   make info <db-name>        - show endpoint / engine / user for the DB
#   make list                  - list all DBs in this deployment

help:
	@echo "Targets:"
	@echo "  make sql-shell <db-name>   open a SQL shell"
	@echo "  make update-db <db-name>   run the update script (CDC test mutations)"
	@echo "  make reset-db  <db-name>   drop + reload from the initial dataset"
	@echo "  make info <db-name>        show endpoint / engine / user"
	@echo "  make list                  list all DBs"
	@echo
	@echo "Examples:"
	@echo "  make sql-shell mysql-aurora-01"
	@echo "  make update-db oracle-rds-02"
	@echo "  make reset-db  sqlserver-rds-03"
	@echo "  make info postgres-rds-01"

sql-shell:
	@./db-shell.sh $(word 2,$(MAKECMDGOALS))

update-db:
	@./db-shell.sh --update $(word 2,$(MAKECMDGOALS))

reset-db:
	@./db-shell.sh --reset $(word 2,$(MAKECMDGOALS))

info:
	@./db-shell.sh --info $(word 2,$(MAKECMDGOALS))

list:
	@./db-shell.sh --list

# Swallow positional args so make doesn't try to build them as targets.
%:
	@:
