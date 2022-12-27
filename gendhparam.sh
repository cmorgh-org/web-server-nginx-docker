#!/usr/bin/env bash

if [ $# -gt 0 ]; then
    # If we passed a command, run it
    exec openssl dhparam -out ../etc/ssl/certs/dhparam.pem $1
else
    # Otherwise start default supervisord
    echo "Default 4096 =>"
    exec openssl dhparam -out ../etc/ssl/certs/dhparam.pem 4096
fi