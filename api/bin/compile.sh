#!/usr/bin/env bash

set -eu
shopt -s globstar

source ../util/util.sh

export PATH=./node_modules/.bin:$PATH
export NODE_PATH=.

readonly SOURCE_TARGET=$(ls util/*.ts route/**/*.ts *.ts)

format "${SOURCE_TARGET}"
validate "${SOURCE_TARGET}"
compile
