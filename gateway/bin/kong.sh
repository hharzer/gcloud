#!/usr/bin/env bash

set -eu

# yay -S openresty luarocks

OPENRESTY_BIN=/opt/openresty/bin
LUAROCKS_HOME=~/.luarocks
LUAROCKS_BIN=$LUAROCKS_HOME/bin
KONG_GITHUB_URI=https://raw.githubusercontent.com/Kong/kong
# KONG_VERSION=2.0.0
KONG_VERSION=1.5.0
KONG_COMMAND_URI=$KONG_GITHUB_URI/$KONG_VERSION/bin/kong
# KONG_CONFIG=config/kong.conf
export PATH=$LUAROCKS_BIN:$OPENRESTY_BIN:$PATH

# rm -rf $LUAROCKS_HOME
# luarocks install kong $KONG_VERSION-0 --local
# curl -sSL $KONG_COMMAND_URI -o $LUAROCKS_BIN/kong
# chmod 755 $LUAROCKS_BIN/kong

# psql postgres vlad
# CREATE USER kong WITH PASSWORD 'Password1!';
# CREATE DATABASE kong WITH OWNER kong;

# export KONG_PREFIX=.
export KONG_DATABASE=postgres
export KONG_PG_HOST=127.0.0.1
export KONG_PG_PORT=5432
export KONG_PG_USER=kong
export KONG_PG_PASSWORD='Password1!'
export KONG_PG_DATABASE=kong

kong migrations bootstrap -v
