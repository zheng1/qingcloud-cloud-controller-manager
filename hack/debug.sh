#!/bin/bash

SKIP_BUILD=no
tag=`git rev-parse --short HEAD`
IMG=magicsong/cloud-manager:$tag
DEST=test/manager.yaml
#build binary

set -e

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--skip-build)
    SKIP_BUILD=yes
    shift # past argument
    ;;
    -n|--NAMESPACE)
    TEST_NS=$2
    shift # past argument
    shift # past value
    ;;
    -t|--tag)
    tag="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [ $SKIP_BUILD == "no" ]; then
    echo "Building binary"
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-w" -o bin/manager ./cmd/main.go

    echo "Building docker image"
    docker build -t $IMG  -f deploy/Dockerfile bin/
    echo "Push images"
    docker push $IMG
    echo "Generating yaml"

fi
sed -e 's@image: .*@image: '"${IMG}"'@' deploy/kube-cloud-controller-manager.yaml > $DEST
kubectl apply -f $DEST