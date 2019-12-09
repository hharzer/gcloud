#!/usr/bin/env bash

set -eu

if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi

source $1

export NODE_PATH=.

export PGHOST=$DB_HOST
export PGPORT=$DB_PORT
export PGDATABASE=$DB_NAME

export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD

export API_PORT=$API_PORT

node main.js
