#!/bin/bash

param="default" # Single Parameter (only one value)
multi=()        # Multiple parameter (can appear on command line more than once, will be added to array) 
flag=${flag:-0} # Flag (boolean, set to 0 if not already set as an environment variable)

while true; do
  case "$1" in
    -p|--param)    shift; param="$1" ;; 
    --param=*)     param="${1#*=}" ;;
    -m|--multi)    shift; multi+=("$1") ;;
    --multi=*)     multi+=("${1#*=}") ;;
    -f|--flag)     flag=1 ;; 
    -n|--no-flag)  flag=0 ;; 
    --)            shift; break ;;   # Explicit end of options
    *)             break ;;          # Implicit end of known options
  esac
  shift
done

# At this point $@ only has unknown options in it
for opt in "$@"; do
  echo "Unknown param $opt"
done

echo "foo=$foo"
echo "bar=$bar"
for m in "${multi[@]}"; do
  echo "multi=>$m"
done
