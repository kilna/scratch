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
export -f _tf_croak

_tf_env_name_from_git_branch() {
  # Determine the git branch we're on and if there's any problems
  local tf_branch=`git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | sed -r -e 's/[^a-z0-9]+/-/g'`
  [[ "$?" -ne "0" ]] && _tf_croak "Failed to determine git branch" "$?"
  [[ "$tf_branch" == 'head' ]] && _tf_croak "Cannot run in git detatched head state" 4
  if [[ "$tf_branch" == "master" ]]; then
    tf_branch="default"
  fi
  echo "$tf_branch"
}
export -f _tf_env_name_from_git_branch

_tf_env_is_currently() {
  local search_tf_env="$1"
echo "SEARCH: $search_tf_env"
echo "CMD: terraform env list | grep -e '^* ' | sed 's/^* //g' | grep -F '${search_tf_env}' | wc -l"
  local tf_env_is_current=`terraform env list | grep -e '^* ' | sed 's/^* //g' | grep -F '${search_tf_env}' | wc -l`
  [[ "$?" -ne "0" ]] && _tf_croak "Error getting `terraform env list`";
echo "FOUND: $tf_env_is_current"
  echo "$tf_env_is_current"
}
export -f _tf_env_is_currently

_tf_env_exists() {
  local search_tf_env="$1"
echo "SEARCH: $search_tf_env"
echo "CMD: terraform env list | sed 's/^[* ]*//g' | grep -F '${search_tf_env}' | wc -l"
  local tf_env_search_found=`terraform env list | sed 's/^[* ]*//g' | grep -F '${search_tf_env}' | wc -l`
  [[ "$?" -ne "0" ]] && _tf_croak "Error getting `terraform env list`";
echo "FOUND: $tf_env_search_found"
  echo "$tf_env_search_found"
}
export -f _tf_env_exists

_tf_env_set_from_git_branch() {
  # Check that we are running as we're expected to
  [[ -n "$BASH_VERSION" ]] || _tf_croak "Must be run from a bash interpreter" 2
  [[ "$BASH_SOURCE" == "$0" ]] && _tf_croak "Script must be sourced into an existing shell rather than executed with a new shell... try 'source $0' in an interactive bash session" 3

  tf_env=`_tf_env_name_from_git_branch`
  if [[ `_tf_env_is_currently $tf_env` -eq "0" ]]; then
    if [[ `_tf_env_exists $tf_env` -ne "0" ]]; then
      terraform env 'select' $tf_env
    else
      echo "It appears you are using terraform in a git branch which resolves to a"
      echo "Terraform environment of: $tf_env"
      echo
      echo "However, this terraform state environment does not appear to exist."
      echo
      read -p "Would you like to create terraform state environment '$tf_env' (y/N)?" \
        -n 1 proceed
      echo
      if [[ "$proceed" == "y" || "$proceed" == "Y" ]]; then
        terraform env new $tf_env
      else
        echo "Aborted." 1>&2
      fi
    fi
  fi

}
export -f _tf_env_set_from_git_branch

# Set the prompt command so that the git branch gets updated every time a new command is run interactively
#export PROMPT_COMMAND='_tf_env_set_from_git_branch'
_tf_env_set_from_git_branch

