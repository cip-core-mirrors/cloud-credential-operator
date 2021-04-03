#!/bin/bash
# Description: container image build & push script
# Author: Patrice Lachance
##############################################################################

opt_push=$1
IMG_NAME="quay.io/cip-core-platform/cloud-credential-operator"
BUILDER_IMAGE=docker.io/golang:latest
RUNTIME_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest

IMG_TAG="$(getcurrent_docker.sh)"
RELEASE="$IMG_TAG"
VERSION="$IMG_TAG"
BUILD_DATE="$(date +'%Y-%M-%d'T'%H:%M:%S%Z')"

# Pulling latest images
docker pull $BUILDER_IMAGE
docker pull $RUNTIME_IMAGE

# Extracting builer images characteristics
BUILDER_GOLANG_VERSION=$(docker inspect $BUILDER_IMAGE| jq -r '.[0].Config.Env | tostring | capture("(?<var>[a-z_A-Z]+)=(?<val>[0-9.]+)") | .val')
RUNTIME_BUILD_DATE=$(docker inspect $RUNTIME_IMAGE| jq -r '.[0].Config.Labels."build-date"')

# Building our image
docker build -t $IMG_NAME:$IMG_TAG \
             --build-arg BUILDER_IMAGE=$BUILDER_IMAGE \
             --build-arg RUNTIME_IMAGE=$RUNTIME_IMAGE \
             --label io.cip.release="$RELEASE" \
             --label io.cip.version="$VERSION" \
             --label io.cip.runtime-image-name="$RUNTIME_IMAGE" \
             --label io.cip.builder-image-name="$BUILDER_IMAGE" \
             --label io.cip.builder-golang-version="$BUILDER_GOLANG_VERSION" \
             --label io.cip.build-date="$BUILD_DATE" \
             --label release="$RELEASE" \
             --label version="$VERSION" \
             --label build-date="$BUILD_DATE" \
             --label com.redhat.build-date="$RUNTIME_BUILD_DATE" \
             -f Dockerfile .

if [ "x$opt_push" == "xpush" ]; then
  docker push $IMG_NAME:$IMG_TAG
fi

