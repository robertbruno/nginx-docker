#!/bin/bash

set -e

# Si la variable DEBUG existe, se mostraran las órdenes y sus argumentos mientras se ejecutan.
[ -n "${DEBUG:-}" ] && set -x

nginx -s reload
