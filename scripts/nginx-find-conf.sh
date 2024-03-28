#!/bin/bash

export basepath=/etc/nginx/conf.d/
export pattern=${pattern:-"*.*"}

usage="
$(basename "$0") [-b /base/path/to] [-p pattern]

Find nginx config

where:
    -h  show this help text
    -b  base path to files              env basepath
    -p  pattern to find                 env pattern
"

while getopts ":h:b:p:" opt; do
  case ${opt} in

    h)      
      printf $usage
      exit 1
      ;;
    b )
      basepath=$OPTARG
      ;;
    p)
      pattern=$OPTARG
      ;;
    \? )
      ;;
    : )
      ;;
  esac
done
shift $((OPTIND -1))

find "$basepath" -type f -name "$pattern"