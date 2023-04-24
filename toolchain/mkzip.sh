#!/bin/sh

uname="$(uname -s)"
case "${uname}" in
    Linux*) zip -r "$@" ;;
    Darwin*) zip -r "$@" ;;
    CYGWIN*) /c/WINDOWS/system32/tar -a -c -f "$@" ;;
    MINGW*) /c/WINDOWS/system32/tar -a -c -f "$@" ;;
    *)
        echo "unknown platform ${uname}"
        exit 1
esac
