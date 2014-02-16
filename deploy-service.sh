#!/bin/bash

## Download Makefile and deploy.sh from github, if they don't exist in
## the work directory. Then pass all the arguments to deploy.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Print commands and their arguments as they are executed
set -x

if [ -e "Makefile" ] ; then
    echo "Use included Makefile"
else
    echo "Download the default Makefile from github"
    wget https://github.com/luckyrandom/r-deploy-git/raw/master/Makefile.default -O Makefile
fi


if [ -e "deploy.sh" ] ; then
    echo "Use included Makefile"
else
    echo "Download the default Makefile from github"
    wget https://github.com/luckyrandom/r-deploy-git/raw/master/deploy.sh -O deploy.sh
fi

chmod u+x deploy.sh && \
./deploy.sh "$@"
