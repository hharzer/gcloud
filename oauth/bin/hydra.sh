#!/usr/bin/env bash

set -eu

export SECRETS_SYSTEM='OryHydraSystemSecret'

# psql postgres vlad
# CREATE USER hydra WITH PASSWORD 'Password1!';
# CREATE DATABASE hydra WITH OWNER hydra;
export DSN='postgres://hydra:Password1!@localhost:5432/hydra?sslmode=disable'

export URLS_SELF_ISSUER=https://localhost:4444/
export URLS_LOGIN=http://localhost:8080/login
export URLS_CONSENT=http://localhost:8080/consent

# hydra migrate sql -e -y
hydra serve all
