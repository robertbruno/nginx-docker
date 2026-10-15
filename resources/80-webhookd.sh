#!/bin/bash
# Arranca webhookd (panel /ops y hooks de gestion) en segundo plano.
#
# Las precondiciones se validan de forma SINCRONA, antes de lanzar el daemon:
# el entrypoint de nginx corre con `set -e`, asi que un exit != 0 aca aborta
# el arranque del contenedor. Lo que va detras de `&` no sirve para eso --
# un job en background devuelve 0 al toque sin importar como termine, que es
# justamente el motivo por el que antes un htpasswd o un webhookd rotos
# pasaban desapercibidos y el contenedor arrancaba sin panel.
set -e

: "${WHD_PASSWD_FILE:?falta WHD_PASSWD_FILE}"
: "${WHD_USER:?falta WHD_USER}"

if [ -z "${WHD_PASSWD:-}" ]; then
    echo "80-webhookd.sh: ERROR WHD_PASSWD vacio; webhookd quedaria sin autenticacion" >&2
    echo "80-webhookd.sh: definir WHD_PASSWD en las variables del servicio" >&2
    exit 1
fi

# htpasswd corre aca y no en el background: si falla, el contenedor no arranca.
mkdir -p "$(dirname "$WHD_PASSWD_FILE")"
echo "$WHD_PASSWD" | htpasswd -i -c -B "$WHD_PASSWD_FILE" "$WHD_USER"

echo "80-webhookd.sh: credenciales listas para el usuario $WHD_USER"

# El daemon si va en background: nginx (PID 1) tiene que seguir arrancando.
nohup webhookd --passwd-file "$WHD_PASSWD_FILE" >/proc/1/fd/1 2>/proc/1/fd/2 &

echo "80-webhookd.sh: webhookd lanzado en el puerto 8080"
