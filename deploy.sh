#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Print commands and their arguments as they are executed
set -x


remote_has_branch() {
    ## FIXME: It may not work properly, if more than one remote exist
    if git branch -r | grep "/$1$" ; then
        return 0
    else
        return 1
    fi
}

## If the remote has the branch, pull it, swith branch and merge
## BRANCH_SRC to it without commit; otherwise, create a new deploy
## branch.
switch_deploybranch() {
    git fetch -p

    if remote_has_branch $BRANCH_DEPLOY; then
        git fetch ${REMOTE} $BRANCH_DEPLOY
        git checkout $BRANCH_DEPLOY
        git merge $BRANCH_SRC --no-commit --no-edit || return 1
        ## FIXME: Fail to merge, need a better way to handle this case
    else
        (git checkout $BRANCH_DEPLOY 2> /dev/null) || \
        (git checkout -b $BRANCH_DEPLOY)
    fi
}

prepare(){
    if [ -z $TRAVIS_BRANCH ] ; then
        echo "Only travis-ci is supported at this moment"
        exit 1
    fi

    mkdir _build
    cd _build
    set +x
    git clone --quiet --depth=50 --branch=${BRANCH_SRC} "$REMOTE_URL_HTTPS" "$PROJECT_NAME" 2>/dev/null 1>/dev/null
    set -x
    cd ${BUILD_DIR}

    if ! ( git diff-index --quiet HEAD ) ; then
        echo "Warning: The work direcotry is not clean. The deploy script may not work as expected."
    fi

    if [[ -e $PROJECT_DIR/Makefile ]]; then
        cp $PROJECT_DIR/Makefile .
    fi

    if [[ -e $PROJECT_DIR/deploy.sh ]]; then
        cp $PROJECT_DIR/deploy.sh .
    fi

    switch_deploybranch
}

runcommand(){
    eval "$@"
}

forceadd(){
    for args in "$@"; do
        echo "Try add $args"
        if $(ls ${args} >/dev/null 2>&1); then
            git add -f $args
        else
            echo "Skip: file $args do not exist"
        fi
    done
}

commit(){
    if  git diff-index --quiet --cached HEAD ; then
        echo "Nothing to deploy"
    else
        git commit -m "pkg built from  $(echo ${SRC_COMMIT_ID} | head -c 8 )"  -m "[ci skip]"
    fi
}

pushremote(){
    set +x
    git push --quiet $REMOTE ${BRANCH_DEPLOY}:${BRANCH_DEPLOY}
    set -x
}

complete(){
    cd "$PROJECT_DIR"
}

deploy_default() {
    if [ -z $TRAVIS_BRANCH ] ; then
        echo "Only travis-ci is supported at this moment"
        exit 1
    fi

    prepare

    if [ -e Makefile ]; then
        runcommand "make"
    else
        runcommand R --slave -e '"library(devtools); document(clean=TRUE, reload=TRUE);"'
    fi

    forceadd "man/*.Rd" "R/RcppExports.R" "src/RcppExports.cpp" "NAMESPACE"

    commit

    pushremote

    complete
}

## From http://stackoverflow.com/questions/3685970/bash-check-if-an-array-contains-a-value
function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

# Set default values
SUFFIX_DEPLOY=${SUFFIX_DEPLOY:-"-pkg"}
BRANCH_SRC=${TRAVIS_BRANCH:-$(git symbolic-ref --short HEAD)}
SRC_COMMIT_ID=$(git rev-parse HEAD)
BRANCH_DEPLOY=${BRANCH_DEPLOY:-${BRANCH_SRC}${SUFFIX_DEPLOY}}
REMOTE=${REMOTE:-origin}
REMOTE_URL=${REMOTE_URL:-$(git config --get remote.$REMOTE.url)}
PROJECT_DIR=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename $PROJECT_DIR)
BUILD_DIR=${PROJECT_DIR}/_build/${PROJECT_NAME}
BRANCHS_TO_DEPLOY=${BRANCHS_TO_DEPLOY:-master}

set +x
REMOTE_URL_HTTPS="https://${GH_TOKEN}@${REMOTE_URL#git://}"
set -x

echo $BUILD_DIR

if ! contains $BRANCHS_TO_DEPLOY $BRANCH_SRC ; then
    echo "Skip. Only branches in ${BRANCHS_TO_DEPLOY} will be deployed"
elif [[ ${TRAVIS_PULL_REQUEST} != "false" ]] ; then
    echo "Skip pull request"
else
    deploy_default
fi
