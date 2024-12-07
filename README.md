# Nginx docker

This project maintains an nginx docker image to cover basic needs, such as a load balancer or distributed proxy pass for:

* Expose services and applications based on their domain names.
* Manage multiple domains (if necessary). Similar to "virtual hosts".
* Enable HTTPS and automatically generate certificates (including renewals) with Let's Encrypt.
* Add HTTP Basic Auth for any services you need to protect that don't have their own security, etc.

## Build

```bash
docker build -t nginx-docker -f Dockerfile .
```

## Config

The nginx configuration is located in the file [nginx.conf](nginx.conf).

> For more info:
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

You can consult Nginx logs by running the following command line on any swarm cluster node:

```bash
docker logs -f  --tail 100 nginx
```

## Utils

Inside the `resources/utils` folder there are several files that will help you configure different features in nginx, for example:

* **[gzip](resources/utils/gzip)** It has the necessary instructions to enable gzip compression on the indicated domain.
* **[host](resources/utils/host)** Allows you to enable the replication of certain headers such as the host.

## Webhookd

A very simple webhook server to launch shell scripts.

In this image we include this tool to have a simple administration and control mechanism, for example to update letsencrypt certificates, enable or disable configurations

You can use the following environment variables to configure:

* WHD_PASSWD_FILE (default: `/etc/webhookd/users.htpasswd`)
* WHD_USER
* WHD_PASSWD

### built-in scripts

In this docker image we include some scripts that will allow you basic administration of some elements, for example run cerbot to create certificates or enable or disable configurations

* **certbot** 

It will execute the certbot command line to generate a new certificate for the indicated domain. Additionally, if the appropriate environment variables have been defined, it will upload said certificate to AWS.

```bash
curl http://localhost:8080/certbot?domain=foo.com&default_mail=foo@mail.com
```

* **nginx-find-conf**

You can check the available nginx configuration

```bash
curl http://localhost:8080/nginx-find-conf
```

* **nginx-enable-conf**

Allows to enable an nginx configuration file

```bash
curl http://localhost:8080/nginx-enable-conf
```
> For the changes to take effect it is recommended to have a volume in the container and restart the nginx service

* **nginx-disable-conf**

Allows to disable an nginx configuration file

```bash
curl http://localhost:8080/nx-disable-conf
```

> For the changes to take effect it is recommended to have a volume in the container and restart the nginx service

## AWS cli

The AWS Command Line Interface (AWS CLI) is a unified tool for managing AWS services. You only need to download and configure a single tool to control multiple AWS services from the command line and automate them using scripts.

In this image we include this tool to have a simple integration mechanism to, for example, upload letsencrypt certificates to AWS

You can use the following environment variables to configure:

*  AWS_REGION (default `us-east-1`)
*  AWS_ACCESS_KEY_ID
*  AWS_SECRET_ACCESS_KEY
*  ALB_ARN
*  ALB_LISTENER_PORT (default `443`)
*  TARGET_GROUP_ARN

## Using environment variables in nginx configuration

Out-of-the-box, nginx doesn't support environment variables inside most configuration blocks. But this image has a function, which will extract environment variables before nginx starts.

Here is an example using docker-compose.yml:

```yaml
web:
  image: nginx
  volumes:
   - ./templates:/etc/nginx/templates
  ports:
   - "8080:80"
  environment:
   - NGINX_HOST=foobar.com
   - NGINX_PORT=80
```

By default, this function reads template files in `/etc/nginx/templates/*.template` and outputs the result of executing envsubst to `/etc/nginx/conf.d`.

So if you place `templates/default.conf.template` file, which contains variable references like this:

```
listen       ${NGINX_PORT};
```

outputs to `/etc/nginx/conf.d/default.conf` like this:

```
listen       80;
```

> Directory which contains template files by default is `/etc/nginx/templates`. For more info:
>
> * [Nginx Docker Official Image](https://hub.docker.com/_/nginx)