#!/bin/bash

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
