#!/bin/bash

# set -x

get_labels(){
    awk -F'[\\[\\]]' '{if ( NF>1 ) { print $2 }}'
}

get_segment(){
    awk -v label="$1" '$0 ~ "^\\["label"\\]$" , $0 ~ "^\\[.*\\]$" && $0 !~ "^\\["label"\\]$"' \
    | tail -n +2 | head -n -1
}

reformat_segment(){
    label="$1"
    echo "[$label]"
    get_segment "$label" \
    | awk 'NF>0' \
    | sort --numeric-sort --ignore-case
    echo 
}

reformat_file(){
    file="$1"
    for label in $(<"$file" get_labels)
    do
        <"$file" reformat_segment "$label"
    done
}

for file in $@
do
    reformat_file "$file" >"$file"
done