#!/bin/bash

# Some common idioms I've used in my bash shell scripting



# Update this script by:
#   curl -sLO https://raw.githubusercontent.com/kilna/scratch/master/bash/common_idioms.sh
# I edit this script in a browser by going to:
#   https://github.com/kilna/scratch/edit/master/bash/common_idioms.sh




### Fail if any command fails, unset vars are used, or pipes fail in the middle

# set -e -u -o pipefail



### Usage

usage() {
  if [[ "${1:-}" ]]; then error "$1"; fi
  cat <<EOF
USAGE: $(basename $0) [ OPTIONS ]
EOF
  if [[ "${1:-}" ]]; then exit ${2:-1}; else exit 0; fi
}



### Command line parameter parsing

# Gets the value of the first --option in $@, returns an exit of 1 if an
# additional shift is needed (i.e., $2 contained the value rather than $1),
# allowing the idiom `option="$(opt "$@")" || shift` to get an option.
# Details at https://github.com/kilna/scratch/blob/master/bash/opt.sh
opt() {
  if [[ "${#1}" -gt 2 && "${1:1:1}" != '-' && "${1:2:1}" != '=' ]]; then echo "${1:2}"
  elif [[ "$1" == *'='* ]]; then echo "${1#*=}"; else echo "$2"; return 1; fi
}

flag=0
param='default_val'
items=()
while [[ $# -gt 0 ]]; do case "$1" in
  --flag|-f)     flag=1;;
  --param*|-p*)  param="$(opt "$@")" || shift;;
  --item*|-i*)   item="$(opt "$@")" || shift; items+=("$item");;
  *)             usage "Unknown option: $1";;
esac; shift; done



### Warnigns, errors and dying in color

ansi_reset="$(tput sgr0)" # ANSI code to reset foreground and background
ansi_warn="$(tput setaf 226 setab 232)" # ANSI code for yellow on black bg
ansi_error="$(tput setaf 196 setab 232)" # ANSI code red on black bg

warn()  { echo "${ansi_warn}$@${ansi_reset}" >&2; }  # Print yellow to STDERR
error() { echo "${ansi_error}$@${ansi_reset}" >&2; } # Print red to STDERR
# Print red error line, with optional exit code (defaults to 1 if not provided)
die() { error "${1:-}"; exit ${2:-1}; }

# Tests
warn 'This is a warning!'
error 'This is an error!'
echo '... this is just a normal message ...'
# die 'This is me dying!'



### Check that a script is being run in bash

if [ ! "$BASH" ]; then
  echo "Script is only compatible with bash, current shell is $SHELL" >&2
  exit 1
fi



### Check that a script is sourced

#if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
#  error 'This script is meant to be added into a Bash shell session.'
#  die "Please call it using: source $(basename $0)"
#fi



### Turn on extglob only for this script

trap "$(shopt -p extglob)" RETURN
shopt -s extglob




### Determine script directory and fully qualified script name

dir="$(cd $(dirname ${BASH_SOURCE[0]}); echo $PWD)"
script="${dir}/$(basename ${BASH_SOURCE[0]})"

# Tests
echo "dir is $dir"
echo "script is $script"



### Uppercase a string

uc() {
  if (( "${BASH_VERSINFO[0]}" > 3 )); then echo "${1^^}"
  else echo "$1" | tr a-z A-Z ;fi
}

# Test
echo $(uc 'lowercase text turned uppercase!')



### Escape

# Escape list entries (if needed) such that they can be eval'd in bash, or just
# generally be printed in a way where the tokens/spacing are explicit
esc() {
  while (( $# > 0 )); do
    if [[ "$1" =~ ^[a-zA-Z0-9_.,:=+/-]+$ ]]; then printf '%s' "$1" # No escaping
    else printf '%s' \'"${1//\'/\'\\\'\'}"\'; fi # Needs escaping
    shift; (( $# > 0 )) && printf ' ' # Add a space between entries
  done
  echo # End with a newline... this'll be removed it run from $(...) anyway
}

# Test
esc This '"is"' a 'test!'



### Loop over a list of variables, dumping their contents

for var in BASH BASH_SOURCE dir script; do echo "$var: ${!var}"; done



### Spinner

# Runs a command, if on a tty it will print a message and spinner on STDERR
# until done, erasing itself with terminal backspaces upon completion
# If not in a tty, it will print the message unadorned to STDERR and the
# command output to STDOUT. Output and exit code cannot be captured so
# success must be tested via other means out of band of the spinned command
spin() {
  local msg=()
  local cmd=()
  while (( $# )); do
    if [[ "$1" == '--' ]]; then shift; cmd=("$@"); break
    else msg+=("$1"); shift; fi
  done
  if (( "${#cmd[@]}" == 0 )); then cmd=("${msg[@]}"); fi
  if [[ -t 1 ]]; then
    echo -n "${msg[@]}" '' >&2
    # Run command in background, redirect its STDOUT and STDERR
    # to filehandle 3
    exec 3< <("${cmd[@]}" 2>&1)
    local out=''
    while true; do
      for spin in '/' '-' '\' '|'; do
        echo -n "$spin" >&2
        if read <&3 line; then # Get line from filehandle 3
          out+="$line"
          sleep 0.01
          echo -ne '\b \b' >&2
        else
          # We reached EOF on filehandle 3, spawned proces is done
          echo -ne '\b \b' >&2
          break 2
        fi
      done
    done
    for x in $(seq 0 $(( ${#msg} + 1 ))); do echo -en '\b \b' >&2; done
    sleep 0.03
  else
    # Run command in foreground
    echo "${msg[@]}" >&2
    "${cmd[@]}"
  fi
}

perlcmd='$|++; for(1..3){ print "$_\n"; print STDERR "ERR: $_\n"; sleep 1 }'
spin 'Test spinner with tty' -- \
  perl -e "$perlcmd"
spin 'Test spinner does not spin when piped from (no tty)' -- \
  perl -e "$perlcmd" | cat -



### Run a command and only echo the output if it fails

# Run a command and only echo the output if it fails. Useful for env setup cmds
# that are run often but you only need to see if something went wrong
quiet_run() {
  local result; result="$("$@" 2>&1)"; exit=$?; (( $exit )) || return 0
  error "Failed:" $(esc "$@"); echo "$result" >&2; exit $exit
}

echo 'Testing success...'
quiet_run perl -e "$perlcmd"
echo 'Testing fail...'
quiet_run perl -e "$perlcmd; exit 1"


