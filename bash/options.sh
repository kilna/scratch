#!/bin/bash

# Pure bash, huffman-coded command line option handling with:
#
#  * Short and long options using a single concise syntax
#  * No external dependencies (no reliance on getopt, easy to copy + paste)
#  * Very few additional lines are required compared to traditional bash
#      methods of parameter handling
#  * --opt=val (equal sign) and --opt val (no equal sign) support without
#      needing separate case declarations for each
#  * --opt key=val (and --opt=key=val) for setting associative array pairs
#      using very easy to read syntax (bash >= 4.0 only)
#  * Support for non-dash options such as +x instead of -x
#  * Pass-through unrecognized post-options as an array ($opt)
#  * Perservation of original $@ array
#
# Copyright Kilna - Released under Creative Commons CC-BY Atribution license

bool=${bool:-0}  # Flag (boolean, set to 0 if not already set via env,
                 #    set by +b or --true, unset by -b or --false )
scalar="default" # Single parameter (only one value, set by --scalar val )
array=()         # Multiple parameter (appears more than once, added to array
                 #    set by passing --array val1 --array val2 )
declare -A hash  # Hash parameter (appears more than once, associative array
                 #   set by passing --hash key1=val1 --hash --key2=val2  )

# Load $@ into $opt array, changing --foo=bar options into separate --foo bar
addopt(){ [[ "$1" == --*=* ]] && opt+=("${1%%=*}" "${1#*=}") || opt+=("$1"); }
opt=(); for option in "$@"; do addopt "$option"; done
# thisopt - get current opt element / shiftopt - shift opt array 1 elem left
thisopt(){ echo "${opt[0]}"; }; shiftopt(){ opt=("${opt[@]:1}"); }
# Set a hash key value pair based on a key=val string, remove if bash < 4.0
hashset(){ eval $1"['${2%%=*}']='${2#*=}'"; }

while true; do case $(thisopt) in

  -s|--scalar) shiftopt; scalar="$(thisopt)"; shiftopt ;;
  -a|--array)  shiftopt; array+=("$(thisopt)"); shiftopt ;;
  -h|--hash)   shiftopt; hashset hash "$(thisopt)"; shiftopt ;;
  +b|--true)   shiftopt; bool=1 ;;
  -b|--false)  shiftopt; bool=0 ;;
  --)          shiftopt; break ;; # Explicit end of options
  -?*)         echo "Unknown option: $(thisopt)" 1>&2; exit 1 ;;
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
