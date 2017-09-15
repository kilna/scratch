#!/bin/bash

tput init
declare -x -A trm
#trm[black]=$(tput setaf 0)
trm[red]=$(tput setaf 1)
trm[green]=$(tput setaf 2)
trm[yellow]=$(tput setaf 3)
trm[blue]=$(tput setaf 4)
trm[magenta]=$(tput setaf 5)
trm[cyan]=$(tput setaf 6)
#trm[white]=$(tput setaf 7)
#trm[blackbg]=$(tput setab 0)
#trm[redbg]=$(tput setab 1)
#trm[greenbg]=$(tput setab 2)
#trm[yellowbg]=$(tput setab 3)
#trm[bluebg]=$(tput setab 4)
#trm[magentabg]=$(tput setab 5)
#trm[cyanbg]=$(tput setab 6)
#trm[whitebg]=$(tput setab 7)
trm[reset]=$(tput sgr0)
trm[bold]=$(tput smso)
trm[nobold]=$(tput rmso)
#trm[dim]=$(tput dim)
trm[rev]=$(tput rev)
#trm[underline]=$(tput smul)
#trm[nounderline]=$(tput rmul)
#trm[clear]=$(tput clear)
trm[default]=$(tput setaf default)

__ps1() {
  echo -n ${trm[blue]}$(__git_ps1)
  if [[ -e .terraform/environment ]]; then
    local workspace=$(<.terraform/environment)
    if [[ "$workspace" == 'default' ]]; then
      echo -n " ${trm[red]}${trm[rev]}[$workspace]${trm[reset]}"
    else
      echo -n " ${trm[magenta]}[$workspace]${trm[reset]}"
    fi
  fi
}

export PS1='\n'${trm[cyan]}'\u@\h`__ps1`\n'${trm[green]}'\w/'${trm[reset]}'\n\$ '

