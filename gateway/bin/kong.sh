#!/usr/bin/env bash

# yay -S openresty luarocks

OPENRESTY_BIN=/opt/openresty/bin
LUAROCKS_HOME=~/.luarocks
LUAROCKS_BIN=$LUAROCKS_HOME/bin
KONG_GITHUB_URI=https://raw.githubusercontent.com/Kong/kong
KONG_VERSION=2.0.0
KONG_COMMAND_URI=$KONG_GITHUB_URI/$KONG_VERSION/bin/kong
export PATH=$LUAROCKS_BIN:$OPENRESTY_BIN:$PATH

rm -rf $LUAROCKS_HOME
luarocks install kong $KONG_VERSION-0 --local
curl -sSL $KONG_COMMAND_URI -o $LUAROCKS_BIN/kong
chmod 755 $LUAROCKS_BIN/kong

kong
