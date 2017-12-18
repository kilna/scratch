#!/bin/bash

foo="default"  # Parameter
bar=0          # Flag
while true; do
  case "$1" in
    -f|--foo)       shift; foo=$1 ;; 
      --foo=*)      foo=${1#*=} ;;
    -b|--bar)       bar=1 ;; 
      -x|--no-bar)  bar=0 ;; 
    --)             shift; break ;; # Explicit end of options
    *)              break ;; # Implicit end of known options
  esac
  shift
done

# At this point $@ only has unknown options in it
for opt in "$@"; do
  echo "Unknown param $opt"
done

echo "foo=$foo"
echo "bar=$bar"
