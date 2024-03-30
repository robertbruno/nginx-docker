#!/bin/bash

set -e

# Si la variable DEBUG existe, se mostraran las órdenes y sus argumentos mientras se ejecutan.
[ -n "${DEBUG:-}" ] && set -x

export basepath=/etc/nginx/conf.d/
export pattern=${pattern:-"*"}
export sufix=${sufix:-".disabled"}

usage="
$(basename "$0") [-b /base/path/to] [-p pattern] [-s sufix]

Enable nginx config (remove .disable sufix)

where:
    -h  show this help text
    -b  base path to files                env basepath
    -p  pattern to find                   env pattern
    -s  remove this sufix from file name  env sufix
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


files=$(find "$basepath" -type f -name "$pattern.conf$sufix")

for file in $files; do
  new_name=${file%$sufix}
  mv -v "$file" "$new_name"
done