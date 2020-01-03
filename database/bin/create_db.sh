#!/usr/bin/env bash

source ./bin/config.sh

# Create database schema
if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi

source $1

set -eu

SQL_DROP_DB="DROP DATABASE IF EXISTS $PGDATABASE;"
SQL_CREATE_DB="CREATE DATABASE $PGDATABASE WITH OWNER $PGUSER;"

export PGDATABASE=postgres

psql -c "${SQL_DROP_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries
psql -c "${SQL_CREATE_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries

export PGDATABASE=identity

psql -f $DB_DIR/identity_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries
# psql -f $DB_DIR/oauth_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries
# psql -f $DB_DIR/pagofx_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries

# Grant access to database
SQL_DROP_ROLE="DROP ROLE IF EXISTS identity_api, identity_api_role;"

psql -c "${SQL_DROP_ROLE}" -v ON_ERROR_STOP=1 -v ECHO=queries
psql -f $DB_DIR/identity_access.sql -v ON_ERROR_STOP=1 -v ECHO=queries
