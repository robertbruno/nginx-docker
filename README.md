# Nginx docker

Este proyecto mantiene una imagen docker de  nginx para cubrir las necesitades dadas para el proyecto tripea, tales como  balanceador de carga o proxy pass distribuido para:

* Exponer servicios y aplicaciones en función de sus nombres de dominio.
* Manejar múltiples dominios (si es necesario). Similar a "hosts virtuales".
* Habilitar HTTPS y generar certificados automáticamente (incluidas las renovaciones) con Let's Encrypt.
* Agregar HTTP Basic Auth para cualquier servicio que necesite proteger y que no tenga su propia seguridad, etc.

## Build

```bash
docker build -t nginx-docker -f Dockerfile .
```

## Config

La configuración del nginx se encuentra en el archivo [nginx.conf](nginx.conf).

> Para mayor información visitar:
>
> * [www.nginx.com](https://www.nginx.com/resources/wiki/start/topics/examples/full/)


## Run

```bash
docker run --rm --name  nginx -p 80:80 -p 443:443 \
    -e  DOMAIN=dominio.com \
    nginx-docker
```

## Check it

* Check if the stack was deployed with:

```bash
docker stack ps nginx
```

## Logs

Puede consultar logs de Nginx ejecute en cualquier nodo del cluster swarm la siguiente línea de comando:

```bash
docker logs -f  --tail 100 nginx
```

## Utils

Dentro de la carpeta `resources/utils` hay varios archivos que le ayudaran a configurar diferentes características en el nginx, ejemplo:

* **[gzip](resources/utils/gzip)** Posee las instrucciones necesarias para habilitar la compresión gzip en el dominio indicado.
* **[host](resources/utils/host)** Permite habilitar la replicación de ciertas cabeceras como el host.
