export GIT_REVISION=$(shell git rev-parse --short HEAD)

REGISTRY = docker.io
REPOSITORY = bluebeluga/kibana

PUSH_REGISTRIES = $(REGISTRY)

export FROM = bluebeluga/alpine

export KIBANA_VERSION=4.5.1
export KIBANA_SHA256=4381c39665c22960bf4db9381a4d9fd9bde159b4d4b13476352bcd2edc960f78
