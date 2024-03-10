# Utiliza la imagen base de Nginx
FROM nginx

COPY default.conf /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf

COPY config.d/tpl /etc/nginx/conf.d/tpl

EXPOSE 80 443

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
