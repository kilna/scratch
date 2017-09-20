#!/bin/bash

docker-machine create -d virtualbox --virtualbox-disk-size "30000" --virtualbox-memory 4096 --virtualbox-cpu-count 3 default
'/c/Program Files/Oracle/VirtualBox/VBoxManage.exe' controlvm default natpf1 tcp-port8080,tcp,,8080,,8080
'/c/Program Files/Oracle/VirtualBox/VBoxManage.exe' controlvm default natpf1 tcp-port443,tcp,,443,,443
'/c/Program Files/Oracle/VirtualBox/VBoxManage.exe' controlvm default natpf1 tcp-port5432,tcp,,5432,,5432
'/c/Program Files/Oracle/VirtualBox/VBoxManage.exe' controlvm default natpf1 tcp-port3306,tcp,,3306,,3306

