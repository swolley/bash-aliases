# cd.               -> navigates back one step
# cd. {number}      -> navigates back {-number} or inner {number} steps
# cd. {foldername}  -> navigates back to {foldername} in current fullpath or search into subdirectories if no parent found
cd.() {
  if [[ $# -eq 0 ]]; then
    cd ..
  elif [[ $1 =~ ^-[0-9]+$ ]]; then
    for i in $( seq 1 ${1#-} ); do
      cd ..
    done
  elif [[ $1 =~ ^[0-9]+$ ]]; then
    local index=$1
    while [ $index -gt 0 ]; do
      local next="$(find . -nowarn -executable -mindepth 1 -maxdepth 1 -type d -not -name '.*' -not -path '*/.*' | sort | head -1)"
      if [[ -n "$next" ]]; then
        cd $next
      fi
      ((index--))
    done
  elif [[ "$PWD" == *"$1"* ]]; then
    while [ $(basename "$PWD") != $1 ]; do
      cd ..
    done
  else
    local next="$(find . -nowarn -executable -type d -not -name '.*' -not -path '*/.*' -iname $1 | sort | head -1)"
    if [[ -n "$next" ]]; then
      cd $next
    else
      echo "bash: cd. $1: Folder not in current path or subdirectories" 1>&2
    fi
  fi
}
