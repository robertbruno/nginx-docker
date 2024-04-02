#!/bin/bash

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

nginx -s reload
