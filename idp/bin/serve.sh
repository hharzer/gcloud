#!/usr/bin/env bash

set -eu

if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi

source $1

export NODE_PATH=.

export IDP_PORT=$IDP_PORT

node main.js
