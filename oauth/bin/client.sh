#!/usr/bin/env bash

set -eu

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

# get_all_clients
# get_client ac-client
# create_client config/ac-client.json
create_client config/cc-client.json
# delete_client ac-client
# delete_all_clients
