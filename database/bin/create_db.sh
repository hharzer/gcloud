#!/usr/bin/env bash

source ./bin/config.sh

if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi
source $1

set -eu

readonly SQL_DROP_DB="DROP DATABASE IF EXISTS $DB_NAME;"
readonly SQL_CREATE_DB="CREATE DATABASE $DB_NAME WITH OWNER $DB_SUPER_USER;"

export PGHOST=$DB_HOST
export PGPORT=$DB_PORT
export PGDATABASE=postgres

export PGUSER=$DB_SUPER_USER
export PGPASSWORD=$DB_SUPER_PASSWORD

psql -c "${SQL_DROP_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries
psql -c "${SQL_CREATE_DB}" -v ON_ERROR_STOP=1 -v ECHO=queries

export PGDATABASE=$DB_NAME

psql -f $DB_DIR/db_schema.sql -v ON_ERROR_STOP=1 -v ECHO=queries
