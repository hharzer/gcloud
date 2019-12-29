#!/usr/bin/env bash

set -eu

if [[ ! -f $1 ]]; then
    echo "ERROR: environment configuration is not provided"
    exit 1
fi

source $1

export NODE_PATH=.
export NODE_TLS_REJECT_UNAUTHORIZED=0

node main.js
