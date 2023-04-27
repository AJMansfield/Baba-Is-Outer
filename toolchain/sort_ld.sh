#!/bin/bash

set -x

get_labels(){
    awk -F'[\\[\\]]' 'BEGIN { ORS = " " } {if ( NF>1 ) { print $2 }}'
}

sort_labels(){
    present=($*)
    order=(general images levels tiles currobjlist icons hotbar)
    # first, run through the order and echo any that are present in the file
    for label in ${order[@]}
    do
        if [[ " ${present[*]} " =~ " $label " ]]
        then
            echo -n "$label "
        fi
    done
    # then, run through all the labels and echo any that weren't specified in the order
    for label in ${present[@]}
    do
        if [[ ! " ${order[*]} " =~ " $label " ]]
        then
            echo -n "$label "
        fi
    done
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
    labels=($(<"$file" get_labels))
    labels=($(sort_labels ${labels[@]}))
    for label in ${labels[@]}
    do
        <"$file" reformat_segment "$label"
    done
}

mk_temp(){
    temp=$(mktemp)
    mk_temp_exit() {
        rm -rf "$temp"
    }
    trap mk_temp_exit EXIT
    echo "$temp"
}

for file in $@
do (
    temp=$(mk_temp)
    cat "$file" > $temp
    reformat_file $temp >"$file"
    rm $temp
)
done