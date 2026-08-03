FROM postgres:18.4

COPY scripts/init_docker-postgres.sh /docker-entrypoint-initdb.d/

COPY --chown=postgres:postgres scripts/chinook_create.sql /opt/rdi-seed/
COPY --chown=postgres:postgres scripts/Chinook_PostgreSql.sql /opt/rdi-seed/

USER postgres

ENV LANG=en_US.UTF8
