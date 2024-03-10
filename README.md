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
    -e  DOMAIN=tripe.com \
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

## Template's

Dentro de la carpeta `tpl` hay varios archivos que le ayudaran a configurar diferentes características en el nginx, ejemplo:

* **[gzip](swarm-server/config.d/tpl/gzip)** Posee las instrucciones necesarias para habilitar la compresión gzip en el dominio indicado.
* **[host](swarm-server/config.d/tpl/host)** Permite habilitar la replicación de ciertas cabeceras como el host.
* **[letsencrypt](swarm-server/config.d/tpl/letsencrypt)** Define los alias necesarios para la gestion del certificado letsencrypt con certbot.
* **[ssl](swarm-server/config.d/tpl/ssl)** Esteblece la configuración mínima para habilitar ssl con un certificado letsencrypt.

## Let's Encrypt

Let's Encrypt es una autoridad de certificación que proporciona certificados X.509 gratuitos. Lo usaremos preferiblemente para el ambiente de QA.

Podemos ejecutar el siguiente comando desde cualquier nodo del cluster swarm para generar un certificado para un dominio:

```bash
docker run --rm -it \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www:/var/www/html/ \
    certbot/certbot \
    certonly \
    --agree-tos \
    --webroot \
    --webroot-path=/var/www/html/ \
    --email account@correo.com \
    -d api.tripea.com
```

En caso de que ya exita un certficado para un dominio en particular y desea expandir ese mismo certificado a un subdominio puede usar la opción de `--expand` el mismo, ej.:

```bash
docker run --rm -it \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt/:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www/:/usr/share/nginx/html/ \
    certbot/certbot \
    certonly \
    --agree-tos \
    --webroot \
    --webroot-path=/usr/share/nginx/html/ \
    --expand \
    -d demo.dominio.com \
    -d api-demo.dominio.com
```

> Cambie los valores de email y dominio según sea el caso, para mayor información visitar:
>
> * [Certbot manual](https://certbot.eff.org/docs/using.html)
>
> * [Certbot docker](https://hub.docker.com/r/certbot/certbot/)
>

Si desea habilitar tráfico ssl, use el siguiente bloque en el archivo de configuración:

```bash
server {
    listen 443;
    server_name demo.dominio.com;

    location / {
        proxy_pass  http://service:80;
    }

    include /etc/nginx/conf.d/tpl/ssl;
}
```


## Renewing certificates

Encrypt CA emite certificados de corta duración (90 días). Asegúrese de renovar los certificados al menos una vez en 3 meses.

Si lo desea ejecutar usted mismo en la línea de comando puede hacerlo de la siguiente forma:

```bash
docker run --rm  \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www:/var/www/html/ \
    certbot/certbot renew
```

> Este comando intenta renovar cualquier certificado obtenido previamente que caduque en menos de 30 días.

## Revoking certificates

Si la clave de su cuenta Let's Encrypt se ha visto comprometida o necesita revocar un certificado, use el comando `revoke` para hacerlo. Tenga en cuenta que dicho comando toma la ruta del certificado (que termina en cert.pem), no un nombre de dominio. Ejemplo:

```bash
docker run --rm  \
  -v /${BASE_PATH}/${PRODUCT_NAME}/letsencrypt:/etc/letsencrypt \
  certbot/certbot revoke \
  --cert-path /etc/letsencrypt/live/CERTNAME/cert.pem \
  --reason affiliationchanged
```

> Los valores de `--reason` deben ser acorde a cada caso, ej: unspecified, keycompromise, affiliationchanged, superseded, and cessationofoperation
> Para más información visitar:
>
> * [certbot revoking](https://certbot.eff.org/docs/using.html#revoking-certificates)
>
