#!/bin/bash

echo $@
for f in "$1"/*.{l,ld,png,txt} ; do
    cp "$f" .
done