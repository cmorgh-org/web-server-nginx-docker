#!/bin/sh

rm ./conf.d/$1.$2.conf
rm ./conf.d/$1.$2.ssl.conf
mkdir -p ./html/$1.$2/public

echo "server {
    listen       80;
    listen  [::]:80;

    server_name $1.$2;

    return 301 https://$1.$2\$request_uri;
}" >> ./conf.d/$1.$2.conf

echo "server {
    listen       443 ssl http2;
    listen  [::]:443 ssl http2;

    server_name $1.$2;

    server_tokens off;

    ssl_certificate /etc/ssl/certs/domains/$2/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/domains/$2/privkey.pem;
    include /etc/nginx/conf.d/sslconf;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html/$1.$2/public;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}" >> ./conf.d/$1.$2.ssl.conf

docker exec -it web-server nginx -s reload
