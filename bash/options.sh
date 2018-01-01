#!/bin/bash

# Pure bash, huffman-coded command line option handling with:
#
#  * Short and long options specified using a single concise syntax
#  * No external dependencies (reliance on getopt, easy to copy + paste)
#  * Very few additional lines are required compared to traditional bash
#      methods of parameter handling
#  * Single-letter / one-dash flags can be bundled (-abc is treated  -a -b -c)
#  * --opt=val (equal sign) and --opt val (no equal sign) support without
#      needing separate case declarations for each
#  * --opt key=val (and --opt=key=val) for setting associative array pairs
#      using very easy to read syntax (bash >= 4.0 only)
#  * Support for non-dash options such as +x instead of -x
#  * Pass-through remaining unrecognized command line args as array ($arg)
#  * Perservation of original $@ array or reset $@ to remaining args
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

args=(); for (( i=1; i<=$#; i++ )); do a="${@:$i:1}"
  [[   "$a" == '--'       ]] && args+=("${@:$i}")            && break
  [[   "$a" == '--'*'='*  ]] && args+=("${a%%=*}" "${a#*=}") && continue
  [[ ! "$a" =~ ^-([^-]+)$ ]] && args+=("$a")                 && continue
  args+=( $( for (( x=1; x<${#a}; x++ )); do echo "-${a:$x:1}"; done ) )
done
arg()      { echo "${args[0]}"; };
nextarg()  { args=("${args[@]:1}"); };
argsleft() { (( "${#args[@]}" > 0 )); };
opt()      { nextarg; eval "$1='$(arg)'"; nextarg; };
flagopt()  { nextarg; eval "$1=${2:-1}"; };
arrayopt() { nextarg; eval "$1+=('$(arg)')"; nextarg; }; 
hashopt()  { nextarg; eval "$1['${args[0]%%=*}']='${args[0]#*=}'"; nextarg; };

while argsleft; do case "$(arg)" in

  -s|--scalar) opt 'scalar' ;;     # Sets $scalar to provided value
  -a|--array)  arrayopt 'array' ;; # Adds value as an element in $array
  -h|--hash)   hashopt 'hash' ;;   # Adds key value to $hash (bash >= 4.0 only)
  +b|--true)   flagopt 'bool' ;;   # Sets $bool to 1
  -b|--false)  flagopt 'bool' 0 ;; # Sets $bool to 0
  --)          nextarg; break ;;   # Explicit end of opts, nix if unneeded
  -?*)         echo "Unknown option: $(arg)" 1>&2; exit 1 ;;
  *)           break ;; # Implicit opts end, exit 1 for only whitelisted opts

esac; done

#set -- "${arg[@]}" # Uncomment to reset the $@ array to $arg (remaining opts)

echo "bool => $bool"
echo "scalar => $scalar"
for elem in "${array[@]}"; do
  echo "array => $elem"
done
for key in "${!hash[@]}"; do
  echo "hash => $key = ${hash[$key]}"
done
# At this point $arg array only has remaining non-option entries from $@
for arg in "${args[@]}"; do
  echo "arg => $arg"
done

