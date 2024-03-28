

nohup bash -c " \
    sleep 3 \
    && mkdir -p $(dirname $WHD_PASSWD_FILE) \
    && echo $WHD_PASSWD | htpasswd -i -c -B $WHD_PASSWD_FILE $WHD_USER \
    && echo 'Running webhookd...' \
    && webhookd --passwd-file $WHD_PASSWD_FILE\
" &