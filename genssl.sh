#!/usr/bin/env bash

if [ $# -gt 0 ]; then
    # If we passed a command, run it
    exec docker run -it --rm -v $(pwd)/../etc/ssl/archive:/etc/letsencrypt/archive -v $(pwd)/../etc/ssl/certs:/etc/letsencrypt/live -v $(pwd)/html/$1/public:/data/letsencrypt -v $(pwd)/html/$1/lib:/var/lib/letsencrypt -v $(pwd)/html/$1/log:/var/log/letsencrypt  certbot/certbot certonly --webroot --register-unsafely-without-email --agree-tos --webroot-path=/data/letsencrypt --staging -d $1
    exec rm -rf ./html/$1/lib
    exec rm -rf ./html/$1/log
else
    # Otherwise start default supervisord
    echo "Please domain of you want to generate certificates for it."
    openssl req -x509 -newkey rsa:4096 -keyout ../etc/ssl/certs/domains/localhost/key.pem -out ../etc/ssl/certs/domains/localhost/cert.pem -sha256 -days 365
fi