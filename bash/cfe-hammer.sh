#!/bin/bash

export dir="/c/Users/kilna/Desktop/firmware/"
export router="192.168.10.1"

wait_for_router() {
  echo -n 'waiting'
  while true; do
    if [[ "$(ping -n 1 -i 1 -w 100 $router)" != *'Average'* ]]; then
      echo -n '.'
      continue
    fi
    if ! curl -s -m 0.01 -o /dev/null http://$router; then
      echo -n '!'
      continue
    fi
    if [[ "$(curl -s -m 2 http://$router)" == *'CFE'* ]] ; then
      echo $'\nbooted to cfe'
    else
      echo $'\nbooted to web gui'
    fi
    break
  done
}

upload() {
  file="$1"
  while ! curl -m 30 -F "files=@$dir/$file" "http://$router/f2.htm"; do
    wait_for_router
  done
}

do_cmd() {
  command="${1// /+}"
  max_time="${2:-10}"
  echo -n "$command"
  while ! curl -s -m $max_time "http://$router/do.htm?cmd=$command"; do
    echo -n '.'
  done
  echo
}

wait_for_router
do_cmd "nvram erase"
upload dd-wrt.v24_micro_generic.bin
wait_for_router
upload TEW-828DRU_v1.0.8.1.bin
wait_for_router
#do_cmd reboot 1

