#!/bin/bash

COMMANDS=('Create domain' 'Create sub-domain' 'Generate new SSL' 'Generate DH-PARAM' "Enable renewal SSL generator with <Let's Encrypt Certbot>")

if [ ! -z "$1" ]; then
    COMMAND="$1"
    _ARGS="$2"
else
    echo "👋 Hello to CMorgh-NginX-CLI"
    echo ""
    echo "Commands:"
    for ((i = 0, j = 1; i < ${#COMMANDS[@]}; i++, j++)); do
        echo "${j}- ${COMMANDS[i]}"
    done
    echo -n "Enter the command number: "
    read COMMAND
fi

case $COMMAND in

    1) # Create domain
        while echo -n "Please enter the domain: "; read DOMAIN; [[ -z "$DOMAIN" ]]; do true; done
        while echo -n "Do you want ssl for this domain? (Y/n) "; read IS_WITH_SSL; ! [[ "$IS_WITH_SSL" =~ ^[YyNn\s]$ ]]; do true; done

        bash ./commands/new-domain.sh $DOMAIN $([[ "$IS_WITH_SSL" =~ ^[Nn]$ ]] && echo "" || echo "--with-ssl")
        ;;

    2) # Create sub domain
        while echo -n "Please enter the sub-domain-key: "; read SUB_DOMAIN; [[ -z "$SUB_DOMAIN" ]]; do true; done
        while echo -n "Please enter the primary-domain without subdomain-key: "; read DOMAIN; [[ -z "$DOMAIN" ]]; do true; done
        while echo -n "Do you want ssl for this domain? (Y/n) "; read IS_WITH_SSL; ! [[ "$IS_WITH_SSL" =~ ^[YyNn\s]$ ]]; do true; done
        
        bash ./commands/new-sub-domain.sh $SUB_DOMAIN $DOMAIN $([[ "$IS_WITH_SSL" =~ ^[Nn]$ ]] && echo "" || echo "--with-ssl")
        ;;

    3) # Generate new SSL
        while echo -n "Please enter your domain: "; read DOMAIN; [[ -z "$DOMAIN" ]]; do true; done
        bash ./commands/genssl.sh $([[ $DOMAIN == "localhost" ]] && echo "" || echo $DOMAIN)
        ;;

    4) # Generate DH-PARAM
        bash ./commands/gendhparam.sh
        ;;

    5) # Enable renewal SSL generator with <Let's Encrypt Certbot>
        mkdir -p ./.cache
        echo "0 0 1 * * sh $PWD/renewssl.sh" >> ./.cache/.crontab
        crontab ./.cache/.crontab
        rm -rf ./.cache/.crontab
        bash ./commands/renewssl.sh
        ;;

    *)
        echo -n "Unknown command"
        ;;
esac