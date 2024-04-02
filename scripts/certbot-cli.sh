#!/bin/bash

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

export params=${params:-"certificates"}

usage="
$(basename "$0") [-p params]

cerbot cli

where:
    -h  show this help text
    -p  string params && comands    env pattern
"

while getopts ":h:p:" opt; do
  case ${opt} in

    h)      
      printf $usage
      exit 1
      ;;
    p)
      params=$OPTARG
      ;;
    \? )
      ;;
    : )
      ;;
  esac
done
shift $((OPTIND -1))

certbot $params
