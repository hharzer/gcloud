#!/usr/bin/env bash

set -eu

# yay -S openresty luarocks

LUA_VERSION=5.1
OPENRESTY_BIN=/opt/openresty/bin
LUAROCKS_HOME=~/.luarocks
LUAROCKS_BIN=$LUAROCKS_HOME/bin
LUAROCKS_SHARE=$LUAROCKS_HOME/share/lua/$LUA_VERSION

KONG_VERSION=2.0.0
KONG_GITHUB_URI=https://raw.githubusercontent.com/Kong/kong
KONG_FILE_URI=$KONG_GITHUB_URI/$KONG_VERSION/bin/kong

RESTY_KONG_TLS_VERSION=0.0.5
RESTY_KONG_TLS_GITHUB_URI=https://raw.githubusercontent.com/Kong/lua-kong-nginx-module
RESTY_KONG_TLS_FILE_URI=$RESTY_KONG_TLS_GITHUB_URI/$RESTY_KONG_TLS_VERSION/lualib/resty/kong/tls.lua

# KONG_CONFIG=config/kong.conf
export PATH=$LUAROCKS_BIN:$OPENRESTY_BIN:$PATH

# rm -rf $LUAROCKS_HOME
# luarocks install kong $KONG_VERSION-0 --local
# curl -sSL $KONG_COMMAND_URI -o $LUAROCKS_BIN/kong
# chmod 755 $LUAROCKS_BIN/kong
# mkdir -p $LUAROCKS_SHARE/resty/kong
# curl -sSL $RESTY_KONG_TLS_FILE_URI -o $LUAROCKS_SHARE/resty/kong/tls.lua

# psql postgres vlad
# CREATE USER kong WITH PASSWORD 'Password1!';
# CREATE DATABASE kong WITH OWNER kong;

export KONG_DATABASE=postgres
export KONG_PG_HOST=127.0.0.1
export KONG_PG_PORT=5432
export KONG_PG_USER=kong
export KONG_PG_PASSWORD='Password1!'
export KONG_PG_DATABASE=kong

# kong migrations bootstrap
kong start
