# Utiliza la imagen base de Nginx
FROM nginx

COPY resources/utils /etc/nginx/utils

COPY resources/templates /etc/nginx/templates

EXPOSE 80 443

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
