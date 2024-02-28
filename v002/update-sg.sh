#!/bin/bash

main() {

  # Check if at least two arguments are provided
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <profile-name> <security-group-id>"
    exit 1
  fi

  SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

  eval "$SCRIPTPATH/remove-ingress.sh $1 $2"
  eval "$SCRIPTPATH/create-ingress.sh $1 $2"

}

main "$@"
