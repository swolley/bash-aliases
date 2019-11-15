# cd.               -> navigates back one step
# cd. {number}      -> navigates back {number} steps
# cd. {foldername}  -> navigates back to {foldername} in current fullpath
cd.() {
    if [[ $# -eq 0 ]]; then
        cd ..
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        for i in $(seq 1 $1); do
            cd ..
        done
    elif [[ "$PWD" == *"$1"* ]]; then
        while [ $(basename "$PWD") != $1 ]; do
            cd ..
        done
    else
        echo "bash: cd.: $1: Folder not in current path" 1>&2
    fi
}
