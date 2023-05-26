#!/bin/bash

if [ ! -d "../etc/ssl/certs/archive/" ]
then
	echo "The SSL archive directory does not exist."
    exit
fi

if [ ! -d "../etc/ssl/certs/domains/" ]
then
	echo "The SSL domains directory does not exist."
    exit
fi

function join_by
{
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

function addDomainInCachedDomains
{
    ! [[ " ${cacheDomains[*]} " =~ " $1 " ]] && cacheDomains+=("$1") || false
}



mkdir -p ./.cache

cacheFileLocation=./.cache/.cache-renewal-auto-ssl
declare -a cacheDomains=()

if [ -f "$cacheFileLocation" ]
then
    while IFS= read -r line; do
        if [ ! -z $(echo "$line" | xargs) ]; then
            addDomainInCachedDomains $line
        fi
    done < "$cacheFileLocation"

    for value in "${cacheDomains[@]}"; do cachedDomainsString+="$value, "; done
    if ! [ ${#cacheFileLocation[@]} -eq 0 ]; then
        if [ -f "$cacheFileLocation" ]; then
            if [[ ${cachedDomainsString[@]:0:-2} != "" ]]
            then
                while echo -n "Do you want regenerate SSL for cached domains? [ ${cachedDomainsString[@]:0:-2} ] (Y/n)"; read regenerateSslForCachedDomains; [[ -z "$regenerateSslForCachedDomains" ]]; do true; done
                [[ "$regenerateSslForCachedDomains" =~ ^[Nn]$ ]] && cacheDomains=()
                cachedDomainsString=""
            else
                cacheDomains=()
                cachedDomainsString=""
            fi
        fi
    fi
fi

### Initialing

# 1- Remove cached file
rm -f $cacheFileLocation

# 2- Get all directories and add to array
for dir in ../etc/ssl/certs/archive/*/; do addDomainInCachedDomains $(basename "$dir"); done
for dir in ../etc/ssl/certs/domains/*/; do addDomainInCachedDomains $(basename "$dir"); done


# 3- Remove 'cli.sh'-path (At etc and domain is empty; then returned it)
cacheDomains=("${cacheDomains[@]/'cli.sh'}")

for value in "${cacheDomains[@]}"
do
if [[ $value =~ [[:alnum:],.]{1,} ]]; then
    echo $value
    cachedDomainsString+="$value, "
fi; done
for dir in "${cacheDomains[@]}"; do echo $dir >> $cacheFileLocation; done

# 4- Remove directories in archive-path and domains-path
for dir in "${cacheDomains[@]}"; do if [[ $dir =~ [[:alnum:],.]{1,} ]]; then rm -rf ../etc/ssl/certs/archive/$dir; fi; done
for dir in "${cacheDomains[@]}"; do if [[ $dir =~ [[:alnum:],.]{1,} ]]; then rm -rf ../etc/ssl/certs/domains/$dir; fi; done

# 5- Generate new SSLs
for domain in "${cacheDomains[@]}"
do if [[ $domain =~ [[:alnum:],.]{1,} ]]; then
    bash ./commands/genssl.sh $domain
fi; done

# 6- Remove cached-file-of-domains
rm -f $cacheFileLocation