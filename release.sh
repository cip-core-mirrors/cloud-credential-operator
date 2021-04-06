#!/usr/bin/env bash
# Description: release script
# Author: Patrice Lachance
# Inspired by:
#   - semtag's release script
#   - https://gist.github.com/bclinkinbeard/1331790
# Dependencies:
#   - [semtag](https://github.com/cip-core-mirrors/semtag)
##############################################################################

###
# Variables
###

IMG_REGISTRY=quay.io
IMG_NAME=cip-core-platform/cloud-credential-operator



###
# Functions
###

_log() {
  echo $*
}

_err() {
  retcode=$1
  shift

  _log $*
  exit $retcode
}


usage() {
  _log "Usage: $0 <semtag command> <semtag scope>"
  _log ""
  _log "  where:"
  _log ""
  _log "     <semtag command>          is one of: final, alpha, beta, candidate"
  _log "     <semtag scope>            is one of: major, minor, patch, auto"
  _log ""
  exit 1
}


commit_code() {
  # current Git branch
  branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
  
  # establish branch and tag name variables
  devBranch="cip-develop"
  masterBranch="cip-master"
  releaseBranch="release-$nextversion"
   
  _log "-> Create the release branch from the -develop branch"
  git checkout -b $releaseBranch $devBranch
   
  # We replace the version in the README file with the new version
  replace="s/^\[Version: [^[]*]/[Version: $nextversion]/g"
  sed -i.bak "$replace" README.CIP.md
  
  # We remove the backup README.CIP.md generated by the sed command
  rm README.CIP.md.bak
  
  # We add both changed files
  if ! git add README.CIP.md ; then
    echo "Error adding modified files with new version"
    exit 1
  fi
  
  if ! git commit -m "Update readme to $nextversion" ; then
    echo "Error committing modified files with new version"
    exit 1
  fi
  
  if ! git push -u origin $releaseBranch; then
    echo "Error pushing modified files with new version"
    exit 1
  fi
  
  _log "-> Creating tag for new version from -master"
  semtag $SEMTAG_COMMAND $SEMTAG_OPTS -f -v $nextversion
   
  # merge release branch with the new version number into master
  _log "-> Checking out branch '$masterBranch'"
  git checkout $masterBranch
  _log "-> Merging '$releaseBranch' in '$masterBranch'"
  git merge --no-ff $releaseBranch -m "merge branch '$releaseBranch' into '$masterBranch'"
  git push -u origin $masterBranch
   
  # merge release branch with the new version number back into develop
  _log "-> Checking out branch '$devBranch'"
  git checkout $devBranch
  _log "-> Merging '$releaseBranch' in '$devBranch'"
  git merge --no-ff $releaseBranch -m "merge branch '$releaseBranch' into '$devBranch'"
  git push -u origin $devBranch
   
  _log "-> Removing release branch '$releaseBranch'"
  git branch -d $releaseBranch
}


build_container_image() {
  # current Git branch
  branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

  git checkout $nextversion
  ./build.sh $1

  git checkout $branch
}



###
# Main logic
###

[ $# -gt 2 ] && usage

SEMTAG_COMMAND="$1"
SEMTAG_SCOPE="$2"

if [ -z "$SEMTAG_COMMAND" ]; then
  SEMTAG_COMMAND="final"
fi

if [ -z "$SEMTAG_SCOPE" ]; then
  SEMTAG_SCOPE="auto"
fi

# We get the next version, without tagging
echo "Getting next version"
nextversion="$(source semtag $SEMTAG_COMMAND $SEMTAG_OPTS -fos $SEMTAG_SCOPE)"
echo "Publishing with version: $nextversion"

# commit code in various branches
commit_code

# create container image and push it to internet registry
build_container_image push
