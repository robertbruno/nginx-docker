# Nginx Docker

Imagen Docker de Nginx con herramientas integradas para gestion de certificados SSL, administracion via webhookd y mantenimiento automatizado de infraestructura AWS.

## Funcionalidades

- Reverse proxy y balanceo de carga basado en dominios (virtual hosts)
- Certificados SSL automaticos con Let's Encrypt (certbot)
- Renovacion y limpieza automatica de certificados via cron
- Administracion remota via webhookd (API HTTP con autenticacion)
- Panel administrativo web en `/ops`
- Mantenimiento automatico de Target Groups en AWS ALB
- Integracion con AWS ACM para importacion de certificados

## Build

```bash
docker build -t nginx-docker .
```

## Run

```bash
docker run --rm --name nginx \
    -p 80:80 -p 443:443 -p 8080:8080 \
    -e FQDN_WEBAPP=admin.example.com \
    -e UPSTREAM_WEBAPP=http://webapp:80 \
    -e FQDN_API=api.example.com \
    -e UPSTREAM_API=http://api:3000 \
    -e WHD_USER=admin \
    -e WHD_PASSWD=secreto \
    nginx-docker
```

## Variables de entorno

### Nginx

| Variable | Default | Descripcion |
|----------|---------|-------------|
| `NGINX_RESOLVER` | `127.0.0.1` | Resolver DNS para nginx |
| `FQDN_*` | -- | Dominio para cada servicio (WEBAPP, API, etc.) |
| `UPSTREAM_*` | -- | URL del upstream para cada servicio |

### Webhookd

| Variable | Default | Descripcion |
|----------|---------|-------------|
| `WHD_USER` | `webhookd` | Usuario para autenticacion HTTP Basic |
| `WHD_PASSWD` | -- | Password para autenticacion |
| `WHD_PASSWD_FILE` | `/etc/webhookd/users.htpasswd` | Archivo htpasswd |
| `WHD_HOOK_TIMEOUT` | `300` | Timeout en segundos para ejecucion de hooks |

### AWS

| Variable | Default | Descripcion |
|----------|---------|-------------|
| `AWS_REGION` | `us-east-1` | Region AWS |
| `AWS_ACCESS_KEY_ID` | -- | Credenciales AWS |
| `AWS_SECRET_ACCESS_KEY` | -- | Credenciales AWS |
| `ALB_ARN` | -- | ARN del Application Load Balancer |
| `ALB_LISTENER_PORT` | `443` | Puerto del listener HTTPS |
| `TARGET_GROUP_ARN` | -- | ARN del Target Group principal |
| `DEFAULT_MAIL` | `test@mail.com` | Email para certificados Let's Encrypt |

## Panel administrativo

Accesible en `http://<host>/ops/`. Interfaz web que permite:

- Ver configuraciones nginx activas y deshabilitadas
- Consultar y renovar certificados SSL (certbot)
- Diagnosticar y corregir Target Groups del ALB
- Ejecutar hooks de webhookd
- Verificar conectividad

Las operaciones requieren autenticacion con las mismas credenciales de webhookd. El panel se sirve como archivo estatico por nginx y las llamadas API pasan por un proxy reverso a webhookd en `/ops/api/`.

## Webhookd - Hooks disponibles

Todos los hooks requieren HTTP Basic Auth y estan disponibles en el puerto 8080.

### Certificados

```bash
# Crear certificado para un dominio
curl -u user:pass "http://host:8080/certbot?domain=example.com&mail=admin@example.com"

# Renovar certificados existentes
curl -u user:pass "http://host:8080/certbot-renew"

# Listar certificados instalados
curl -u user:pass "http://host:8080/certbot-cli?params=certificates"

# Revocar certificado
curl -u user:pass "http://host:8080/certbot-revoke?domain=example.com"
```

### Configuracion Nginx

```bash
# Listar configuraciones
curl -u user:pass "http://host:8080/nginx-find-conf"

# Ver contenido de una configuracion
curl -u user:pass "http://host:8080/nginx-show-conf?pattern=api"

# Habilitar configuracion
curl -u user:pass "http://host:8080/nginx-enable-conf?pattern=api.https"

# Deshabilitar configuracion
curl -u user:pass "http://host:8080/nginx-disable-conf?pattern=api.https"

# Recargar nginx
curl -u user:pass "http://host:8080/nginx-reload"
```

### Target Groups (AWS ALB)

```bash
# Diagnostico y auto-correccion de targets
curl -u user:pass "http://host:8080/update-targets"
```

## Cron jobs

La imagen ejecuta tres tareas automaticas:

| Frecuencia | Script | Funcion |
|------------|--------|---------|
| Diario 00:00 | `certbot-renew.sh` | Renueva certificados Let's Encrypt e importa a AWS ACM |
| Semanal dom 03:00 | `delete-expired-certificates.sh` | Elimina certificados expirados de ACM y listeners del ALB |
| Cada 5 min | `update-targets.sh` | Detecta la IP actual del contenedor y corrige targets unhealthy en los Target Groups del ALB |

## Configuracion Nginx con templates

Los archivos en `/etc/nginx/templates/*.template` se procesan automaticamente con `envsubst` al iniciar el contenedor. El resultado se escribe en `/etc/nginx/conf.d/`.

Ejemplo de template:

```nginx
server {
    listen 80;
    server_name ${FQDN_API};

    set $upstream_api "${UPSTREAM_API}";

    location / {
        proxy_pass $upstream_api;
        include /etc/nginx/utils/host;
        include /etc/nginx/utils/gzip;
    }

    include /etc/nginx/utils/letsencrypt;
}
```

## Utils

Archivos de configuracion reutilizables en `resources/utils/`:

- **gzip** - Habilita compresion gzip
- **host** - Replica headers del cliente al upstream (Host, X-Real-IP, X-Forwarded-For)
- **ssl** - Configuracion SSL/TLS
- **letsencrypt** - Location block para validacion ACME de Let's Encrypt

## Estructura del proyecto

```
.
├── Dockerfile
├── nginx.conf
├── resources/
│   ├── 80-webhookd.sh          # Entrypoint: inicia webhookd
│   ├── 90-cron.sh              # Entrypoint: inicia cron
│   ├── admin/
│   │   └── index.html          # Panel administrativo
│   ├── crontab                 # Definicion de cron jobs
│   ├── templates/              # Templates de configuracion nginx
│   │   ├── default.conf.template
│   │   ├── api.conf.template
│   │   ├── api.https.conf.disabled.template
│   │   ├── webapp.conf.template
│   │   └── webapp.https.conf.disabled.template
│   └── utils/                  # Includes reutilizables
│       ├── gzip
│       ├── host
│       ├── letsencrypt
│       └── ssl
└── scripts/
    ├── certbot.sh              # Crear certificados
    ├── certbot-cli.sh          # Consultar certificados
    ├── certbot-renew.sh        # Renovar certificados + ACM
    ├── certbot-revoke.sh       # Revocar certificados
    ├── delete-expired-certificates.sh  # Limpiar ACM
    ├── nginx-disable-conf.sh   # Deshabilitar config
    ├── nginx-enable-conf.sh    # Habilitar config
    ├── nginx-find-conf.sh      # Listar configs
    ├── nginx-reload.sh         # Recargar nginx
    ├── nginx-show-conf.sh      # Ver contenido de config
    └── update-targets.sh       # Mantener targets del ALB
```
