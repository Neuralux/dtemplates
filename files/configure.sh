#!/bin/bash

instance=""
defaults=""
mustache=""
src=""
dest=""
mode=""
owner=""
group=""
token="## token ##"

while getopts :n:m:s:d:D:M:O:G opt; do
    case "$opt" in
        n) instance=$OPTARG
           ;;
        m) mustache=$OPTARG
           ;;
        s) src=$OPTARG
           ;;
        d) dest=$OPTARG
           ;;
        t) token=$OPTARG
           ;;
        D) defaults=$OPTARG
           ;;
        M) mode=$OPTARG
           ;;
        O) owner=$OPTARG
           ;;
        G) group=$OPTARG
           ;;
    esac
done

cd "$(dirname "$0")"


## TODO use defaults if src kv isn't there
sed '1,/${token}/d' ${src} |
    while read -r key val
    do
        echo "export $key=$val" >> /tmp/${instance}.sh
    done

source /tmp/${instance}.sh
rm ${dest}
mo ${mustache} >> ${dest}
chmod ${mode} ${dest}
chown ${owner}:${group} ${dest}

exit $0;
