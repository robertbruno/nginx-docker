# Utiliza la imagen base de Nginx
FROM nginx

COPY config.d /etc/nginx/conf.d

COPY tpl /etc/nginx/tpl

EXPOSE 80 443

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
