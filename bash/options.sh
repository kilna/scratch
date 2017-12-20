#!/bin/bash

# Pure bash, huffman-coded option handling

bool=${bool:-0}  # Flag (boolean, set to 0 if not already set via env, 
                 #    set by --true, unset by --false )
scalar="default" # Single parameter (only one value, set by --scalar val )
array=()         # Multiple parameter (appears more than once, added to array
                 #    set by passing --array val1 --array val2 )
declare -A hash  # Hash parameter (appears more than once, associative array
                 #   set by passing --hash key1=val1 --hash --key2=val2  )

# Load $@ into $opt array, changing --foo=bar options into separate --foo bar
addopt() { [[ "$1" == '--'*'='* ]] && opt+=(${1%%=*} ${1#*=}) || opt+=($1); };
opt=(); for option in "$@"; do addopt "$option"; done
# thisopt - get current opt element / shiftopt - shift opt array 1 elem left
thisopt(){ echo "${opt[0]}"; }; shiftopt() { opt=("${opt[@]:1}"); };
# Set a hash key value pair based on a key=val string
hashset() { hashname=$1; kv=$2; eval $hashname"[${kv%%=*}]='${kv#*=}'"; };

while true; do case $(thisopt) in

  -s|--scalar) shiftopt; scalar=$(thisopt); shiftopt ;;
  -a|--array)  shiftopt; array+=($(thisopt)); shiftopt ;;
  -h|--hash)   shiftopt; hashset hash $(thisopt); shiftopt ;;
  -t|--true)   shiftopt; bool=1 ;;
  -f|--false)  shiftopt; bool=0 ;;
  --)          shiftopt; break ;; # Explicit end of options
  -?*)         echo "Unknown option "$(thisopt) 1>&2; exit 1 ;;
  *)           break ;; # Implicit end of options
  
esac; done

echo "bool => $bool"
echo "scalar => $scalar"
for elem in "${array[@]}"; do
  echo "array => $elem"
done
for key in "${!hash[@]}"; do
  echo "hash => $key = ${hash[$key]}"
done
# At this point $opt array only has remaining non-option entries from $@
for option in "${opt[@]}"; do
  echo "opt => $option"
done
