#!/usr/bin/env bash

set -eu

# psql postgres vlad
# CREATE USER hydra WITH PASSWORD 'Password1!';
# CREATE DATABASE hydra WITH OWNER hydra;
export DSN='postgres://hydra:Password1!@localhost:5432/hydra?sslmode=disable'

# IdP configuration
export URLS_SELF_ISSUER=https://localhost:4444/
export URLS_LOGIN=http://localhost:9090/login
export URLS_CONSENT=http://localhost:9090/consent
export URLS_LOGOUT=http://localhost:9090/logout
export URLS_ERROR=http://localhost:9090/error
export URLS_POST_LOGOUT_REDIRECT=http://localhost:9090/post_logout_redirect

export TTL_AUTH_CODE=2m
export TTL_ACCESS_TOKEN=5m
export TTL_REFRESH_TOKEN=30m
export TTL_ID_TOKEN=10m

export SECRETS_SYSTEM='OryHydraSecretsSystem'

# hydra migrate sql -e -y
# hydra serve all # (public + admin)
# https://localhost:4444 -> public interface
#     /auth, /token, /revoke, /userinfo, /.well-known
# https://localhost:4445 -> admin interface
#     /keys, /clients, /introspect, /requests, /sessions


export HYDRA_PUBLIC_URI=https://localhost:4444
export HYDRA_ADMIN_URI=https://localhost:4445

function create_client {
    local client_json=${1:?ERROR: client JSON definition is not provided}

    curl -s -k -X POST $HYDRA_ADMIN_URI/clients -d @$client_json | jq --indent 4 .
}

function get_client {
    local client_id=${1:?ERROR: mandatory client_id is not provided}

    curl -s -k -X GET $HYDRA_ADMIN_URI/clients/$client_id | jq --indent 4 .
}

function delete_client {
    local client_id=${1:?ERROR: mandatory client_id is not provided}

    curl -s -k -X DELETE $HYDRA_ADMIN_URI/clients/$client_id
}

function get_all_clients {
    curl -s -k -X GET $HYDRA_ADMIN_URI/clients | jq --indent 4 .
}

function delete_all_clients {
    for client_id in $(get_all_clients | jq -r '.[].client_id'); do
        delete_client $client_id
    done
}

get_all_clients
# get_client auth-code-client
# create_client client/ac-client.json
# create_client client/cc-client.json
# delete_client ac-client
# delete_all_clients
