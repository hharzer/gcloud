#!/usr/bin/env bash

source ./bin/config.sh

if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi
source $1

set -eu

pgcli -h $DB_HOST -p $DB_PORT $DB_NAME $DB_SUPER_USER
