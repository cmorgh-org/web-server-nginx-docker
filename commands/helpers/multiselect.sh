#!/bin/bash 
#####################################################################################################################
#
#           R5: MAJ 22/11/2021 : EML 
#               - Pb d'affichage du menu sur on dépasse la taille de l'écran
#               - On restreint le choix au 40 derniers fichiers
#           R6: MAJ 23/11/2021 : EML 
#               - On détermine automatiquement la taille de l'écran pour vérifier que l'affichage est Ok
#               - On affichera le menu compatible du coup
#               - Ajout des flèche gauche/droite pour une évolution sur un menu à plusieurs colonnes parametrables
#           R7: MAJ 24/11/2021 : EML 
#               - Correction pour support toute version de bash
#               - version < 4.3 : option "local -n" inconnue ==> fonction xxx_43m
#               - version > 4.3 : option "local -n" reconnue ==> fonction xxx_43p
#               - Possibilité de délectionner tout ou rien
#           R8: MAJ 24/11/2021 : EML 
#               - Correction checkwinsize
#               - Correction positionnement sur la fenetre
#
#
# SOURCES :
#   https://www.it-swarm-fr.com/fr/bash/menu-de-selection-multiple-dans-le-script-bash/958779139/ 
#   https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu/415155#415155
#
#####################################################################################################################
export noir='\e[0;30m'
export gris='\e[1;30m'
export rougefonce='\e[1;31m'
export rouge='\e[0;31m'
export rose='\e[1;31m'
export vertfonce='\e[0;32m'
export vertclair='\e[1;32m'
export orange='\e[0;33m'
export jaune='\e[1;33m'
export bleufonce='\e[0;34m'
export bleuclair='\e[1;34m'
export violetfonce='\e[0;35m'
export violetclair='\e[1;35m'
export cyanfonce='\e[0;36m'
export cyanclair='\e[1;36m'
export grisclair='\e[0;37m'
export blanc='\e[1;37m'
export neutre='\e[0;m'

function checkwinsize {
    local __items=$1
    local __lines=$2
#local __err=$3

    if [ $__items -ge $__lines ]; then
#       echo "La taille de votre fenêtre ne permet d'afficher le menu correctement..."
        return 1
    else
#       echo "La taille de votre fenêtre est de $__lines lignes, compatible avec le menu de $__items items..."
        return 0
    fi
} 
function multiselect_43p {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }

    local return_value=$1
    local colmax=$2
    local offset=$3
    local -n options=$4
    local -n defaults=$5
    local title=$6
    local LINES=$( tput lines )
    local COLS=$( tput cols )

    clear

#   checkwinsize $(( ${#options[@]}/$colmax )) $LINES
    err=`checkwinsize $(( ${#options[@]}/$colmax )) $(( $LINES - 2)); echo $?`

    if [[ ! $err == 0 ]]; then
        echo "La taille de votre fenêtre est de $LINES lignes, incompatible avec le menu de ${#_liste[@]} items..."
            cursor_to $lastrow
        exit
    fi 

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    cursor_to $(( $LINES - 2 ))
    printf "_%.s" $(seq $COLS)
    echo -e "$bleuclair / $title / | $vertfonce select : key [space] | (un)select all : key ([n])[a] | move : arrow up/down/left/right or keys k/j/l/h | validation : [enter] $neutre\n" | column  -t -s '|'

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local lastcol=`get_cursor_col`
    local startrow=1
    local startcol=1

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = "h" ]]; then echo left; fi;
        if [[ $key = "l" ]]; then echo right; fi;
        if [[ $key = "a" ]]; then echo all; fi;
        if [[ $key = "n" ]]; then echo none; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
            if [[ $key = [C || $key = l ]]; then echo right;  fi;
            if [[ $key = [D || $key = h ]]; then echo left;  fi;
        fi 
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    toggle_option_multicol() {
        local option_row=$1
        local option_col=$2

    if [[ $option_row -eq -10 ]] && [[ $option_row -eq -10 ]]; then
        for ((option=0;option<${#selected[@]};option++)); do
                    selected[option]=true
        done
    else
        if [[ $option_row -eq -100 ]] && [[ $option_row -eq -100 ]]; then
            for ((option=0;option<${#selected[@]};option++)); do
                        selected[option]=false
            done
        else
            option=$(( $option_col + $option_row * $colmax )) 

                if [[ ${selected[option]} == true ]]; then
                        selected[option]=false
                else
                    selected[option]=true
                fi
            fi
    fi

    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

    curr_idx=$(( $curr_col + $curr_row * $colmax ))

        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[38;5;46m✔\e[0m]"
            fi

            row=$(( $idx/$colmax ))
        col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }


    local active_row=0
    local active_col=0


    while true; do
        print_options_multicol $active_col $active_row 

        # user key control
        case `key_input` in
            space)  toggle_option_multicol $active_row $active_col;;
            enter)  print_options_multicol -1 -1; break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax -1 )) ; fi;;
            all)    toggle_option_multicol -10 -10 ;;
            none)   toggle_option_multicol -100 -100 ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
    clear
}

function multiselect_43m {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }

    local return_value=$1
    local colmax=$2
    local offset=$3
    local size=$4
    shift 4

    local options=("$@")
    shift $size

    for i in $(seq 0 $size); do
        unset options[$(( $i + $size ))]
    done

    local defaults=("$@")
    shift $size

    unset defaults[$size]

    local title="$@"

#   local options=("${!tmp_options}")
#   local defauts=("${!tmp_defaults}")

    local LINES=$( tput lines )
    local COLS=$( tput cols )

    clear

#   checkwinsize $(( ${#options[@]}/$colmax )) $LINES
#   echo ${#options[@]}/$colmax
#   exit

    err=`checkwinsize $(( ${#options[@]}/$colmax )) $(( $LINES - 2)); echo $?`

    if [[ ! $err == 0 ]]; then
        echo "La taille de votre fenêtre est de $LINES lignes, incompatible avec le menu de ${#_liste[@]} items..."
            cursor_to $lastrow
        exit
    fi 

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    cursor_to $(( $LINES - 2 ))
    printf "_%.s" $(seq $COLS)
    echo -e "$bleuclair / $title / | $vertfonce select : key [space] | (un)select all : key ([n])[a] | move : arrow up/down/left/right or keys k/j/l/h | validation : [enter] $neutre\n" | column  -t -s '|'
     
    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local lastcol=`get_cursor_col`
    local startrow=1
    local startcol=1

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = "h" ]]; then echo left; fi;
        if [[ $key = "l" ]]; then echo right; fi;
        if [[ $key = "a" ]]; then echo all; fi;
        if [[ $key = "n" ]]; then echo none; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
            if [[ $key = [C || $key = l ]]; then echo right;  fi;
            if [[ $key = [D || $key = h ]]; then echo left;  fi;
        fi 
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    toggle_option_multicol() {
        local option_row=$1
        local option_col=$2

    if [[ $option_row -eq -10 ]] && [[ $option_row -eq -10 ]]; then
        for ((option=0;option<${#selected[@]};option++)); do
                    selected[option]=true
        done
    else
        if [[ $option_row -eq -100 ]] && [[ $option_row -eq -100 ]]; then
            for ((option=0;option<${#selected[@]};option++)); do
                        selected[option]=false
            done
        else
            option=$(( $option_col + $option_row * $colmax )) 

                if [[ ${selected[option]} == true ]]; then
                        selected[option]=false
                else
                    selected[option]=true
                fi
            fi
    fi

    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

    curr_idx=$(( $curr_col + $curr_row * $colmax ))

        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[38;5;46m✔\e[0m]"
            fi

            row=$(( $idx/$colmax ))
        col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }


    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row 

        # user key control
        case `key_input` in
            space)  toggle_option_multicol $active_row $active_col;;
            enter)  print_options_multicol -1 -1; break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax -1 )) ; fi;;
            all)    toggle_option_multicol -10 -10 ;;
            none)   toggle_option_multicol -100 -100 ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
    clear
}
