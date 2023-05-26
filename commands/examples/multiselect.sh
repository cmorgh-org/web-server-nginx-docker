#!/bin/bash

if [ -e ./commands/helpers/multiselect.sh ]; then
    source ./commands/helpers/multiselect.sh
else
    echo "script menu.sh introuvable dans le répertoire courant"
    exit
fi

LINES=$( tput lines )
COLS=$( tput cols )

clear

#Définition de mes listes 

for ((i=0; i<10; i++)); do
    _liste[i]="Choix $i"
    _preselection_liste[i]=false
done

colmax=1
offset=$(( $COLS / $colmax ))

VERSION=`echo $BASH_VERSION | awk -F\( '{print $1}' | awk -F. '{print $1"."$2}'`

if [ $(echo "$VERSION >= 4.3" | bc -l) -eq 1 ]; then
    multiselect_43p result $colmax $offset _liste _preselection_liste "CHOIX DU DEPOT" 
else
    multiselect_43m result $colmax $offset ${#_liste[@]} "${_liste[@]}" "${_preselection_liste[@]}" "CHOIX DU DEPOT" 
fi

idx=0
dbg=1
status=1
for option in "${_liste[@]}"; do
    if  [[ ${result[idx]} == true ]]; then
        if [ $dbg -eq 0 ]; then
                echo -e "$option\t=> ${result[idx]}"
        fi
        TARGET=`echo $TARGET ${option}`
        status=0
    fi  
        ((idx++))
done

if [ $status -eq 0 ] ; then
    echo -e "$vertfonce Choix des items validé :\n$vertclair $TARGET $neutre"
else
    echo -e "$rougefonce Aucun choix d'items détecté... $neutre"
    exit
fi

while true; do
    case `key_input` in
            enter)  break;;
        esac
done

clear