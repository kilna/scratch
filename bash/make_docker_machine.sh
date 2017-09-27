#!/bin/bash

make_docker_machine() {

  set -e

  local machine_name="default"
  local ports=(80 8000 8080 443 3306 5432 5000)
  local adapters=(natpf1)

  while true; do
    [[ $(docker-machine rm --force "${machine_name}" 2>&1 | grep -F 'Host does not exist' ) != '' ]] && break
    sleep 1
  done

  docker-machine create -d virtualbox --virtualbox-disk-size "30000" \
      --virtualbox-memory 4096 --virtualbox-cpu-count 3 "${machine_name}"

  for port in "${ports[@]}"; do
    for adapter in "${adapters[@]}"; do
      /c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe controlvm "${machine_name}" "${adapter}" \
          "port-${port},tcp,,${port},,${port}"  
    done
  done

  eval `docker-machine env`
  
  set +e
}

make_docker_machine
