#!/bin/bash

CONF_FILE="/opt/AdGuardHome/upstream.conf"
FILE_URL="https://github.com/vrichv/CNSiteList/releases/latest/download/cn-domain-agh.txt"

if [ -f "$CONF_FILE" ]; then
    file=$(mktemp)
    grep -v "^\[" $CONF_FILE >> $temp_file
    curl -L --retry 10 --retry-delay 5 $FILE_URL -o /tmp/cn-domain-latest.txt
    if [ $? -eq 0 ]; then
        cat /tmp/cn-domain-latest.txt >> $temp_file
        mv $temp_file $CONF_FILE
        systemctl restart AdGuardHome
    fi
fi
