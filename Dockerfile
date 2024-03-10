# Utiliza la imagen base de Nginx
FROM nginx

# Copia el archivo de configuración personalizado a la ubicación adecuada en el contenedor
COPY default.conf /etc/nginx/conf.d/default.conf

# Copia los archivos estáticos de tu aplicación a la ubicación adecuada en el contenedor
COPY html /usr/share/nginx/html

# Expone el puerto 80 para que puedas acceder a tu aplicación a través de él
EXPOSE 80

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
