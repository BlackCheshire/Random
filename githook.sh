#!/bin/bash

ZERO_COMMIT="0000000000000000000000000000000000000000"

while read -r OLDREV NEWREV REFNAME; do

    if [[ "$NEWREV" = "$ZERO_COMMIT" ]]
    then
        # Branch or tag got deleted
        continue
    elif [[ "$OLDREV" = "$ZERO_COMMIT" ]]
    then
        # New branch or tag
        SPAN=$(git rev-list "$NEWREV" --not --all)
    else
        SPAN=$(git rev-list "$OLDREV".."$NEWREV" --not --all)
    fi

    for COMMIT in $SPAN
    do
        AUTHOR=$(git log --format=%an -n 1 "$COMMIT")
        CURRENT_HOUR=$(date +"%H")
        if [[ $AUTHOR -eq "Artur" || $AUTHOR -eq "222" ]]; then
        echo "Hello maintainer"
        exit 0
        fi

        if [[ $REFNAME == refs/heads/develop ]]; then
                if [[ $CURRENT_HOUR -ge 17 || $CURRENT_HOUR -le 8 ]]; then
                echo "WARNING: Time of develop freeze!"
                exit 1
                fi
        else
                exit 0
        fi
    done
done
