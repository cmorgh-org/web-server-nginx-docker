#!/bin/sh

rm ./conf.d/$1.conf
rm ./conf.d/$1.ssl.conf
mkdir -p ./html/$1/public

echo "server {
    listen       80;
    listen  [::]:80;

    server_name $1 www.$1;

    # For certbot ssl generator configs
    location ~ /.well-known/acme-challenge {
        root /usr/share/nginx/html/$1/public;
    }
    root /usr/share/nginx/html/$1/public;
    index index.html;
}" >> ./conf.d/$1.conf

docker exec -it web-server nginx -s reload


if [[ $2 == '--with-ssl' ]]; then

bash ./genssl.sh $1

rm ./conf.d/$1.conf
echo "server {
    listen       80;
    listen  [::]:80;

    server_name $1 www.$1;

    # For certbot ssl generator configs
    location ~ /.well-known/acme-challenge {
        root /usr/share/nginx/html/$1/public;
    }

    location / {
        return 301 https://www.$1\$request_uri;
    }
}" >> ./conf.d/$1.conf

echo "server {
    listen       443 ssl http2;
    listen  [::]:443 ssl http2;

    server_name $1;

    server_tokens off;

    ssl_certificate /etc/ssl/certs/domains/$1/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/domains/$1/privkey.pem;
    include /etc/nginx/conf.d/sslconf;

    return 301 https://www.$1\$request_uri;
}

server {
    listen       443 ssl http2;
    listen  [::]:443 ssl http2;

    server_name www.$1;

    server_tokens off;

    ssl_certificate /etc/ssl/certs/domains/$1/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/domains/$1/privkey.pem;
    include /etc/nginx/conf.d/sslconf;

    #access_log  /var/log/nginx/host.access.log  main;

    location ~ /.well-known/acme-challenge {
        root /usr/share/nginx/html/$1/public;
    }

    location / {
        root   /usr/share/nginx/html/$1/public;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}" >> ./conf.d/$1.ssl.conf

docker exec -it web-server nginx -s reload

fi
