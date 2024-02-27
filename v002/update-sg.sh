#!/bin/bash

main() {

  # Check if at least two arguments are provided
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <profile-name> <security-group-id>"
    exit 1
  fi

  eval "./remove-ingress.sh $1 $2"
  eval "./create-ingress.sh $1 $2"

}

main "$@"
