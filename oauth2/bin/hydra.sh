#!/usr/bin/env bash

set -eu

# psql postgres vlad
# CREATE USER hydra WITH PASSWORD 'Password1!';
# CREATE DATABASE hydra WITH OWNER hydra;
export DSN='postgres://hydra:Password1!@localhost:5432/hydra?sslmode=disable'

export SECRETS_SYSTEM='OryHydraSecretsSystem'

# Token configuration
export TTL_AUTH_CODE=1m
export TTL_ACCESS_TOKEN=1h
export TTL_REFRESH_TOKEN=2m
export TTL_ID_TOKEN=1m

# IdP configuration
export URLS_SELF_ISSUER=https://localhost:4444/
export URLS_LOGIN=http://localhost:4000/login
export URLS_CONSENT=http://localhost:4000/consent
export URLS_LOGOUT=http://localhost:4000/logout
export URLS_ERROR=http://localhost:4000/error
export URLS_POST_LOGOUT_REDIRECT=http://localhost:4000/post-logout

# hydra migrate sql -e -y
hydra serve all # (public + admin)

# https://localhost:4444 -> public interface
#     /auth, /token, /revoke, /userinfo, /.well-known
# https://localhost:4445 -> admin interface
#     /keys, /clients, /introspect, /requests, /sessions
