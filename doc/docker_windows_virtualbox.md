# Docker + VirtualBox (Instead of Hyper-V)

* Uninstall "Docker for Windows" if it has been installed already
* Disable Hyper-V + restart
* Intall Docker Toolbox, making sure that "Add docker binaries to PATH" is checked
* Open the Docker Quickstart terminal

Verify the default environment was created successfully:
```$ docker-machine ls
NAME                ACTIVE   DRIVER       STATE     URL                        SWARM
dev                 *        virtualbox   Running   tcp://192.168.99.100:2376```
 
Re-create "default" with some different parameters, so delete the "default" docker-machine:

```$ docker-machine stop default
Stopping "default"...
Machine "default" was stopped.
$ docker-machine rm default
About to remove default
WARNING: This action will delete both local reference and remote instance.
Are you sure? (y/n): y
Successfully removed default```

Check that the docker-machine was removed (there should no longer be a listing for "default"):

```$ docker-machine ls
NAME ACTIVE DRIVER STATE URL SWARM```

Create "default" again, specifying how much memory, disk and CPU you want to use.

```$ docker-machine create -d virtualbox --virtualbox-disk-size "100000" --virtualbox-memory 4096 --virtualbox-cpu-count 3
 default```
 
Verify the default environment was created successfully:

```$ docker-machine ls
NAME                ACTIVE   DRIVER       STATE     URL                        SWARM
dev                 *        virtualbox   Running   tcp://192.168.99.100:2376```
 
Set up port forwarding to that docker-machine:
```$ '/c/Program Files/Oracle/VirtualBox/VBoxManage.exe' controlvm default natpf1 tcp-port8080,tcp,,8080,,8080```
 
Set up Git Bash to load docker environment variables:

```$ cat 'eval $(docker-machine env default)' >> ~/.bash_profile```
