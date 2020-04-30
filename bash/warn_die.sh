#!/bin/bash

ansi_reset="$(tput sgr0)" # ANSI code to reset foreground and background
ansi_warn="$(tput setaf 226 setab 232)" # ANSI code for yellow on black bg
ansi_error="$(tput setaf 196 setab 232)" # ANSI code red on black bg

warn()  { echo "${ansi_warn}$@${ansi_reset}" >&2; }  # Print yellow to STDERR
error() { echo "${ansi_error}$@${ansi_reset}" >&2; } # Print red to STDERR
# Print red error line, with optional exit code (defaults to 1 if not provided)
die() { error "${1:-}"; exit ${2:-1}; }

### Tests below

warn 'This is a warning!'
error 'This is an error!'
echo '... this is just a normal message ...'
die 'This is me dying!'
