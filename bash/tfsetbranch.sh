#!/bin/bash

# Bail out from sourcing or direct run, with a message and an optional exit code number
_tf_croak() {
  echo "tfsetbranch: $1" 1>&2
  croak_exit=1
  [ "$2" != "" ] && croak_exit="$2"
  ( [[ -n "$ZSH_EVAL_CONTEXT" && "$ZSH_EVAL_CONTEXT" =~ :file$ ]] || 
    [[ -n "$KSH_VERSION" && $(cd "$(dirname -- "$0")" && printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] ||
    [[ -n "$BASH_VERSION" && "$0" != "$BASH_SOURCE" ]] 
  ) && return "$croak_exit" || exit "$croak_exit"
}

_tf_set_git_branch() {
  # Check that we are running as we're expected to
  [[ -n "$BASH_VERSION" ]] || _tf_croak "Must be run from a bash interpreter" 2
  [[ "$BASH_SOURCE" == "$0" ]] && _tf_croak "Script must be sourced into an existing shell rather than executed with a new shell... try 'source $0' in an interactive bash session" 3

  # Reset the git branch variable as used by our terraform inventories
  unset TF_VAR_git_branch

  # Determine the git branch we're on and if there's any problems
  branch=`git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | sed -r -e 's/[^a-z0-9]+/-/g'`
  [[ "$?" -ne "0" ]] && _tf_croak "Failed to determine git branch" "$?"
  [[ "$branch" == 'head' ]] && _tf_croak "Cannot run in git detatched head state" 4

  # If there were no problems, set the var used by our terraform inventories
  export TF_VAR_git_branch="$branch"

  [[ -n "$TF_SET_GIT_BRANCH_DEBUG" ]] &&
    echo "PROMPT_COMMAND: $PROMPT_COMMAND" &&
    echo "TF_VAR_git_branch: $TF_VAR_git_branch"
}

# Export the functions used in this script
export -f _tf_croak
export -f _tf_set_git_branch
# Set the prompt command so that the git branch gets updated every time a new command is run interactively
export PROMPT_COMMAND='_tf_set_git_branch'
_tf_set_git_branch

echo "Your bash session will now automatically update the terraform variable git_branch"
echo "(via the env var TF_VAR_git_branch) based on the git branch of the current directory"
echo

