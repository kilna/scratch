#!/bin/bash

# Pure bash, huffman-coded command line option handling with:
#
#  * Short and long options specified using a single concise syntax
#  * No external dependencies (no reliance on getopt, easy to copy + paste)
#  * Very few additional lines are required compared to traditional bash
#      methods of parameter handling
#  * Single-letter / one-dash flags can be bundled (-abc is treated  -a -b -c)
#  * --opt=val (equal sign) and --opt val (no equal sign) support without
#      needing separate case declarations for each
#  * --opt key=val (and --opt=key=val) for setting associative array pairs
#      using very easy to read syntax (bash >= 4.0 only)
#  * Support for non-dash options such as +x instead of -x
#  * Pass-through remaining unrecognized post-options as an array ($opt)
#  * Perservation of original $@ array or reset $@ to post-options
#
# Copyright Kilna - Released under Creative Commons CC-BY Atribution license

bool=${bool:-0}  # Flag (boolean, set to 0 if not already set via env,
                 #    set by +b or --true, unset by -b or --false )
scalar="default" # Single parameter (only one value, set by --scalar val )
array=()         # Multiple parameter (appears more than once, added to array
                 #    set by passing --array val1 --array val2 )
declare -A hash  # Hash parameter (appears more than once, associative array
                 #   set by passing --hash key1=val1 --hash --key2=val2
                 #   bash >= 4.0 only)

# Load $@ into $opt array, splitting --foo=bar options into separate --foo bar
# and splitting bundled -abc into separate -a -b -c
opt=();
for o in "$@"; do
  [[ "$o" == --*=* ]] \
    && opt+=("${1%%=*}" "${1#*=}") \
    || [[ "$o" =~ ^-([^-]*)$ && "${BASH_REMATCH[1]}" =~ ${BASH_REMATCH[1]//?/(.)} ]] \
      && opt+=($(for x in "${BASH_REMATCH[@]:1}"; do echo -n "-$x "; done)) \
      || opt+=("$o")
done

for option in "${opt[@]}"; do
  echo "opt => $option"
done

optshift () { opt=("${opt[@]:1}"); }; # Shift $opt array 1 element left
option () { echo -n "${opt[0]}"; }; # Current option (index 0 in $opt array)
optval () { optshift; echo -n "${opt[0]}"; optshift; }; # Process options having values
moreopts () { (( "${#opt}" >= 1 )); }; # Are there remaining options?
# Set key to value in hash based on a key=val string, remove if bash < 4.0
hashopt () { local kv="$(optval)"; eval "$1['${kv%%=*}']='${kv#*=}'"; };

while moreopts; do case "$(option)" in

  -s|--scalar) scalar="$(optval)" ;;
  -a|--array)  array+=("$(optval)") ;;
  -h|--hash)   hashopt hash ;; # bash >= 4.0 only
  +b|--true)   bool=1; optshift ;;
  -b|--false)  bool=0; optshift ;;
  --)          optshift; break ;; # Explicit end of options, nix if unneeded
  -?*)         echo "Unknown option: $(option)" 1>&2; exit 1 ;;
  *)           break ;; # Implicit end of opts, exit 1 here to whitelist opts

esac; done

#set -- "${opt[@]}" # Uncomment to reset the $@ array to $opt (remainder)

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
