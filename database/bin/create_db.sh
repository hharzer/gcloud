#!/usr/bin/env bash

source ./bin/config.sh

# Create database schema
if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi

source $1

set -eu

SQL_DROP_DB="DROP DATABASE IF EXISTS $DB_NAME;"
SQL_CREATE_DB="CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;"

export PGHOST=$DB_HOST
export PGPORT=$DB_PORT
export PGDATABASE=postgres

export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD

psql -c "${SQL_DROP_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries
psql -c "${SQL_CREATE_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries

export PGDATABASE=$DB_NAME

# psql -f $DB_DIR/identity_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries
# psql -f $DB_DIR/oauth_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries
psql -f $DB_DIR/pagofx_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries

# # Grant access to database
# source ./config/api.sh

# DB_ROLE=identity_api_role

# SQL_DROP_ROLE="DROP ROLE IF EXISTS $DB_USER, $DB_ROLE;"
# SQL_CREATE_ROLE="CREATE ROLE $DB_ROLE;
# GRANT USAGE ON SCHEMA identity TO $DB_ROLE;
# GRANT SELECT, INSERT, UPDATE , DELETE
#    ON TABLE identity.user, identity.user_audit TO $DB_ROLE;
# CREATE ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD' LOGIN;
# GRANT $DB_ROLE TO $DB_USER;"

# psql -c "${SQL_DROP_ROLE}" -v ON_ERROR_STOP=1 -v ECHO=queries
# psql -c "${SQL_CREATE_ROLE}" -v ON_ERROR_STOP=1 -v ECHO=queries
