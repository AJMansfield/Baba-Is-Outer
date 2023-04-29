#!/bin/bash
set -x
scriptDir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

babaLogDir="${1:-"${scriptDir}/../log/"}"
shift

if [ -d "$babaLogDir" ]
then
    babaStdout="$(mktemp --tmpdir="$babaLogDir" baba-stdout-XXXXX.txt)"
    tmpbase="$(basename "$babaStdout")"
    babaStderr="$(dirname "$babaStdout")/baba-stderr-${tmpbase#baba-stdout-}"
else
    babaStdout="/dev/stdout"
    babaStderr="/dev/stderr"
fi

echo "Logging to ${babaStdout} and ${babaStderr}" >&2

babaId=736260
uname="$(uname -s)"
case "${uname}" in
    Linux*)
        steamPath='~/.local/share/Steam'
        steamBin='steam'
        babaPath="${steamPath}/steamapps/common/Baba Is You"
        babaBin="Baba Is You"
        ;;
    Darwin*) 
        steamPath='~/.local/share/Steam'
        steamBin='steam'
        babaPath="${steamPath}/steamapps/common/Baba Is You"
        babaBin="Baba Is You"
        ;;
    CYGWIN*)
        steamPath='/c/Program Files (x86)/Steam'
        steamBin="${steamPath}/steam.exe"
        babaPath="${steamPath}/steamapps/common/Baba Is You"
        babaBin="Baba Is You.exe"
        ;;
    MINGW*)
        steamPath='/c/Program Files (x86)/Steam'
        steamBin="${steamPath}/steam.exe"
        babaPath="${steamPath}/steamapps/common/Baba Is You"
        babaBin="Baba Is You.exe"
        ;;
    *)
        echo "unknown platform ${uname}"
        exit 1
esac


if [ -f "${babaPath}/${babaBin}" ]
then
    pushd "$babaPath"
    "$babaBin" $@ >"$babaStdout" 2>"$babaStderr"
    popd
else
    "${steamBin}" -applaunch $babaId "$@" >"$babaStdout" 2>"$babaStderr"
fi