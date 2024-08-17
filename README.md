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

## webhookd

A very simple webhook server to launch shell scripts.

In this image we include this tool to have a simple administration and control mechanism, for example to update letsencrypt certificates, enable or disable configurations

You can use the following environment variables to configure:

* WHD_PASSWD_FILE (default: `/etc/webhookd/users.htpasswd`)
* WHD_USER
* WHD_PASSWD

## AWS Cli

The AWS Command Line Interface (AWS CLI) is a unified tool for managing AWS services. You only need to download and configure a single tool to control multiple AWS services from the command line and automate them using scripts.

In this image we include this tool to have a simple integration mechanism to, for example, upload letsencrypt certificates to AWS

You can use the following environment variables to configure:

*  AWS_REGION (default `us-east-1`)
*  AWS_ACCESS_KEY_ID
*  AWS_SECRET_ACCESS_KEY
*  ALB_ARN
*  ALB_LISTENER_PORT (default `443`)
*  TARGET_GROUP_ARN
