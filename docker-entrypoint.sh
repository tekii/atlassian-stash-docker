#!/bin/bash
# exit on error
#set -e

#
START=${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh
STOP=${BITBUCKET_INSTALL_DIR}/bin/stop-bitbucket.sh

_sigterm() {
  echo "ENTRYPOINT: Caught SIGTERM signal!"
  kill -TERM "$pid" 2>/dev/null
}


#trap "${STOP}; exit" SIGHUP SIGINT SIGTERM
#trap _die_pls SIGKILL SIGTERM SIGHUP SIGINT EXIT
trap _sigterm SIGTERM

# Preconditions

echo "ENTRYPOINT: starting server in foreground."

${START} -fg &

pid=$!

echo "ENTRYPOINT: waiting to $pid to die."

wait "$pid"

echo "ENTRYPOINT: exit."
