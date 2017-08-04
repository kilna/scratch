#!/bin/bash
user=${1:-kilna}
curl -s https://api.github.com/users/$user/repos\?per_page\=200 | \
  grep ssh_url | \
  cut -d \" -f 4 | \
  xargs -L1 git clone
