#!/bin/bash

ss64pwd_sha1sum() {
    if which sha1sum &> /dev/null
    then
        sha1sum # consumes stdin
    else
        shasum -a 1 # consumes stdin
    fi
}

ss64pwd_sha256sum() {
    if which sha256sum &> /dev/null
    then
        sha256sum # consumes stdin
    else
        shasum -a 256 # consumes stdin
    fi
}

ss64pwd_find_clipboard_manager() {
    which gclip pbcopy | grep -v -m 1 'not found'
}

ss64pwd_to_clipboard() {
    if (($1==1)) && clm=$(ss64pwd_find_clipboard_manager)
    then
        eval ${clm} # consumes stdin
        echo -n '(in clipboard)'
    else
        cat # consumes stdin
    fi
}

strongpw() {
    [[ "$1" != "" ]] || return
    one_arg=0
    (($#==1)) && one_arg=1
    read -rs -p 'Encryption key: ' key
    [[ "$key" != "" ]] || return
    echo ''
    while [[ "$1" != "" ]]
    do
        echo -n "Password for $1: " # line break
        echo -n "$key:$1"                                    |
            ss64pwd_sha256sum                                |
            perl -ne "s/([0-9a-f]{2})/print chr hex \$1/gie" |
            base64                                           |
            tr +/ Ea                                         |
            cut -b 1-20                                      |
            xargs printf %s                                  |
            ss64pwd_to_clipboard $one_arg
        shift
    done
    echo
    echo -n 'Verification code: '
    echo -n ":$key:" | ss64pwd_sha256sum | perl -ne "s/([0-9a-f]{2})/print chr hex \$1/gie" | base64 | tr +/ Ea | cut -b 1-20
}

stdpw() {
    [[ "$1" != "" ]] || return
    one_arg=0
    (($#==1)) && one_arg=1
    read -rs -p 'Encryption key: ' key
    [[ "$key" != "" ]] || return
    echo ''
    while [[ "$1" != "" ]]
    do
        echo -n "Password for $1: " # line break
        echo -n "$key:$1"                                    |
            ss64pwd_sha1sum                                  |
            perl -ne "s/([0-9a-f]{2})/print chr hex \$1/gie" |
            base64                                           |
            cut -b 1-8                                       |
            perl -pe "s/$/1a/"                               |
            xargs printf %s                                  |
            ss64pwd_to_clipboard $one_arg
        shift
    done
    echo -n 'Verification code: '
    echo -n ":$key:" | ss64pwd_sha256sum | perl -ne "s/([0-9a-f]{2})/print chr hex \$1/gie" | base64 | tr +/ Ea | cut -b 1-20
}

