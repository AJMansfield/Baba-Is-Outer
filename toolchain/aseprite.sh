#!/bin/sh

asepriteId=431730

uname="$(uname -s)"
case "${uname}" in
    Linux*)
        steamPath='~/.local/share/Steam'
        steamBin='steam'
        asepriteBin="${steamPath}/steamapps/common/Aseprite/Aseprite"
        ;;
    Darwin*) 
        steamPath='~/.local/share/Steam'
        steamBin='steam'
        asepriteBin="${steamPath}/steamapps/common/Aseprite/Aseprite"
        ;;
    CYGWIN*)
        steamPath='/c/Program Files (x86)/Steam'
        steamBin="${steamPath}/steam.exe"
        asepriteBin="${steamPath}/steamapps/common/Aseprite/Aseprite.exe"
        ;;
    MINGW*)
        steamPath='/c/Program Files (x86)/Steam'
        steamBin="${steamPath}/steam.exe"
        asepriteBin="${steamPath}/steamapps/common/Aseprite/Aseprite.exe"
        ;;
    *)
        echo "unknown platform ${uname}"
        exit 1
esac

if [ -f "${asepriteBin}" ] ;
then
    set -x
    "${asepriteBin}" $@
else
    set -x
    "${steamBin}" -applaunch $asepriteId "$@"
fi