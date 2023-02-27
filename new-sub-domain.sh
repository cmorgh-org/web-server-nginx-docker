#!/bin/sh

rm ./conf.d/$1.$2.conf
rm ./conf.d/$1.$2.ssl.conf
mkdir -p ./html/$1.$2

echo "server {
    listen       80;
    listen  [::]:80;

    server_name $1.$2;

    # For certbot ssl generator configs
    location ~ /.well-known/acme-challenge {
        allow all;
        root /usr/share/nginx/html/$1.$2/public;
    }
    root /usr/share/nginx/html/$1.$2/public;
    index index.html;
}" >> ./conf.d/$1.$2.conf


if [[ $3 == '--with-ssl' ]]; then

rm ./conf.d/$1.$2.conf
echo "server {
    listen       80;
    listen  [::]:80;

    server_name $1.$2;

    return 301 https://$1.$2\$request_uri;
}" >> ./conf.d/$1.$2.conf

echo "server {
    listen       443 ssl http2;
    listen  [::]:443 ssl http2;

    server_name  $1.$2;

    server_tokens off;

    ssl_certificate /etc/ssl/certs/domains/$2/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/domains/$2/privkey.pem;
    include /etc/nginx/conf.d/sslconf;

    # For certbot ssl generator configs
    location ~ /.well-known/acme-challenge {
        allow all;
        root /usr/share/nginx/html/$1.$2/public;
    }
    root /usr/share/nginx/html/$1.$2/public;
    index index.html;
}" >> ./conf.d/$1.$2.ssl.conf

fi

docker exec -it web-server sh nginx -s reload