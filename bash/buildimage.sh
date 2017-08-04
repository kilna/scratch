#!/bin/bash
set -e

usage() {
  [[ ! -z "$1" ]] && echo "$1"$'\n\n' 1>&2
  cat <<EOF
USAGE: $0 [options]

OPTIONS:
  -v or --verbose  Turns on bash debug mode to show details of all commands run
  -n or --no-cache Turns off docker image caching to perform the build
  -h or --help     Show this message and exit

Builds a magento docker image and runs it in a new container.

If there is an env.sh file, it will be sourced in order to set up variables
used by this script and the regression Dockerfile, it will look something like:

export image_name="hobbyist"                       # Name of the docker image to create
export container_name="hobbyist"                   # Name of the docker container spin up using the image
export repo_name="connect20-qa01.magedevteam.com"  # Which php composer repo to use
export repo_user=""                                # Which php composer repo username to use
export repo_pass=""                                # Password for the above user
export repo_stability="dev"                        # Which level of stability to request from the php composer repo
EOF
  [[ ! -z "$2" ]] && exit "$2"
  exit
}

re_run=0
rebuild=0
for opt in "$@"; do
  case "$opt" in
    -n|--no-cahce) no_cache=1 ;;
    -v|--verbose)  set -x ;;
    -h|--help)     usage ;;
    *)             usage "Unknown parameter $opt" 1 ;;
  esac
  shift
done

[[ -f './env.sh' ]] && source './env.sh'
[[ -f 'Dockerfile' ]] || usage "$0 must be run from a directory with a Dockerfile in it" 2

# Determine if required vars are set, if they aren't then complain and stop
REQUIRED_VARS=(image_name container_name repo_name repo_user repo_pass repo_stability)
errs=0
for env_var in "${REQUIRED_VARS[@]}"; do
  [[ $(eval "echo \$$env_var") == "" ]] || continue
  echo "Required env var ${env_var} is not set" 1>&2
  errs+=1
done
if [[ "${errs}" -ne 0 ]]; then
  cat <<EOF 1>&2
Recommended usage is to set these variables in an env.sh file
located in the same directory as the Dockerfile being built

For more information run:

  $0 --help

EOF
  exit $errs
fi

run() {
  echo
  echo '-------------------------------------------------------------------------------'
  echo "$1"
  echo '-------------------------------------------------------------------------------'
  eval "$1"
  [[ "$?" -eq '0' ]] || exit $?
  echo
}

# Stop the container if present
if [[ $(docker inspect -f '{{.State.Running}}' "${image_name}" 2>/dev/null) == "true" ]]; then
  run "docker stop '${container_name}'"
fi

# Remove the image if present
if [[ $(docker images -q "${container_name}" 2>/dev/null) != "" ]]; then
  run "docker rmi -f '${image_name}'"
fi

# Create the image
opts=''
(( $no_cache )) && opts+=" --no-cache --pull"
opts=" --build-arg repo_user='${repo_user}'"
opts+=" --build-arg repo_pass='${repo_pass}'"
opts+=" --build-arg repo_name='${repo_name}'"
opts+=" --build-arg repo_stability='${repo_stability}'"
run "docker build -t '${image_name}' $opts ."

# Remove the container if present
echo $(docker rm -f '${container_name}' 2>/dev/null)

# Run a container with the new image
run "docker run -d --name '${container_name}' --shm-size 1024MB -p 8080:80 '${image_name}'"

# Look at the logs from the newly run container
sleep 10
run "docker logs '${container_name}'"

