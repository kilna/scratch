#!/bin/bash

# A pure-bash huffman-coded option handler

# Long/commented version:

# Echoes the value of the next option in "$@", fails if an additional shift is needed
#
# Valid opt styles:   -a val   -aval   -a=val   --arg val   --arg=val
#
# Options cannot be bundled

# Typically used like:
#
#    timeout=60
#    while [[ $# -gt 0 ]]; do case "$1" in
#        -t*|--timeout*)  timeout="$(opt "$@")" || shift;;
#        *)               echo "Unknown option: $1" >&2; exit 1;;
#    esac; shift; done

# Caveat:
# Default pattern of using a case pattern of --optname*) means that --optnameblah would
# match and be processed in the same way. As a result, if you need to parse any option
# that is a substring of another, different option, you should process long options
# first in your case statement

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

# Gets the value of the next option in $@, fails if an additional shift is needed
# Details at https://github.com/kilna/scratch/blob/master/bash/opt.sh
opt() {
  if [[ "${#1}" -gt 2 && "${1:1:1}" != '-' && "${1:2:1}" != '=' ]]; then echo "${1:2}"
  elif [[ "$1" == *'='* ]]; then echo "${1#*=}"; else echo "$2"; return 1; fi
}

# Copyright 2019 Kilna, Anthony; released under MIT license https://opensource.org/licenses/MIT
# ...do what you like with it, but it would be nice if you include the link to here
