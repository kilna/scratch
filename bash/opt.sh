#!/bin/bash

# Echoes the value of an option, returns a non-zero exit if a shift is needed
# Valid opt styles:   -a val   -aval   -a=val   --arg val   --arg=val
# Options cannot be bundled
#
# Typically used like:
#
# timeout=60
# while [[ $# -gt 0 ]]; do case "$1" in
#   -t*|--timeout*)  timeout="$(opt "$@")" || shift;;
#   *)               die "Unknown option: $1";;
# esac; shift; done
#
opt() {
  if [[ "${#1}" -gt 2 && "${1:1:1}" != '-' && "${1:2:1}" != '=' ]]; then
    # Looks like -aval (but not -a=val), return character 2 onward
    echo "${1:2}"
  elif [[ "$1" == *'='* ]]; then
    # Looks like -a=val or --arg=val, return everything past the '='
    echo "${1#*=}"
  else
    # Looks like the value is supposed to be in the next element,
    # echo that value and return an exit code so the receiver can know
    # to shift the $@ array by an additional element.  We can't modify
    # the parent's $@ array, so this is the easiest way to do this
    echo "$2"
    return 1
  fi
}

# Compact version:

# Echoes the value of an option, returns a non-zero exit if a shift is needed
opt() {
  if [[ "${#1}" -gt 2 && "${1:1:1}" != '-' && "${1:2:1}" != '=' ]]; then echo "${1:2}"
  elif [[ "$1" == *'='* ]]; then echo "${1#*=}"; else echo "$2"; return 1; fi
}
