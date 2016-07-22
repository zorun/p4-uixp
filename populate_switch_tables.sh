#!/bin/sh

BASEDIR="$(dirname $BASH_SOURCE)"

"$BASEDIR"/../submodules/bm/tools/runtime_CLI.py --thrift-port 10001 < "$BASEDIR/commands.txt"
