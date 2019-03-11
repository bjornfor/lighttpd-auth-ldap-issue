#!/usr/bin/env bash
# Fake cgit implementation that handles git clone over dumb http protocol.

echo "cgit.cgi begin (pid=$$)" >&2

rootdir="$(dirname "$(readlink -f "$0")")/git-repos"
#rootdir="$PWD/git-repos"
if [ "x$PATH_INFO" != x ] && [ "x$PATH_INFO" != x/ ]; then
    f="$rootdir$PATH_INFO"
    if [ -e "$f" ]; then
        printf "HTTP/1.1 200\r\n"
        printf "Content-type: application/octet-stream\r\n"
        printf "\r\n"
        cat "$f"
    else
        printf "HTTP/1.1 404\r\n"
        printf "\r\n"
    fi
else
    printf "HTTP/1.1 200\r\n"
    printf "Content-type: text/plain; charset=UTF-8\r\n"
    printf "\r\n"
    echo "fake-cgit: Hello, this is the root, listing git repos:"
    printf "\r\n"
    ls -1 "$rootdir" | while read line; do echo "  $line"; done
fi

echo "cgit.cgi end (pid=$$)" >&2
