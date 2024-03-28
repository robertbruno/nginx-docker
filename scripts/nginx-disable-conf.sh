#!/bin/bash

export basepath=${basepath:-"/etc/nginx/conf.d/"}
export pattern=${pattern:-"*"}
export sufix=${sufix:-".disabled"}

usage="
$(basename "$0") [-b /base/path/to] [-p pattern] [-s sufix]

Disable nginx config (add .disable sufix)

where:
    -h  show this help text
    -b  base path to files              env basepath
    -p  pattern to find                 env pattern
    -s  save config as this new sufix   env sufix
"

while getopts ":h:b:p:s:" opt; do
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
    s )
      sufix=$OPTARG
      ;;      
    \? )
      ;;
    : )
      ;;
  esac
done
shift $((OPTIND -1))

find "$basepath" -type f -name "$pattern.conf" -exec bash -c "mv -v {} {}$sufix" \;