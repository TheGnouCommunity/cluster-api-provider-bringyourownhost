# Copyright 2021 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Build and push (opt-in) a BYOH bundle to repository
#
# 1. Download bundle ingredients. See ingredients/deb/download.sh
# 2. Mount the bundle ingredients under /ingredients
# 3. Optional. Mount output bundle directory under /bundle
# 3. Optional. Mount additional configuration under /config
#	-v config/ubuntu/20_04/k8s/1_22:/config
#	Defaults to config/ubuntu/20_04/k8s/1_22
# Example
# // Build and push a BYOH bundle to repository
# docker run --rm -v <INGREDIENTS_HOST_ABS_PATH>:/ingredients --env BUILD_ONLY=0 <THIS_IMAGE> <REPO>/<BUNDLE IMAGE>
#
# // Build and store a BYOH bundle
# docker run --rm -v <INGREDIENTS_HOST_ABS_PATH>:/ingredients  -v <BUNDLE_OUTPUT_ABS_PATH>:/bundle --env <THIS_IMAGE>

ARG BASE_IMAGE=ubuntu:20.04
FROM $BASE_IMAGE as build

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
                    --no-install-recommends \
                    ca-certificates \
                    curl

ARG ARCH=amd64
ARG IMGPKG_VERSION=v0.42.1
RUN curl -LOJR https://github.com/carvel-dev/imgpkg/releases/download/$IMGPKG_VERSION/imgpkg-linux-$ARCH \
 && mv imgpkg-linux-$ARCH /usr/local/bin/imgpkg \
 && chmod +x /usr/local/bin/imgpkg
# If set to 1 bundle is built and available as bundle/bundle.tar
# If set to 0 bundle is build and pushed to repo
ENV BUILD_ONLY=1

WORKDIR /bundle-builder
COPY ingredients/*.sh ./
RUN chmod a+x *.sh
#Default config
COPY ./conf/ /conf/

RUN mkdir /ingredients && mkdir /bundle
ENV PATH="/bundle-builder:${PATH}"

WORKDIR /tmp/bundle
ENTRYPOINT ["build-push-bundle.sh", "/ingredients", "/conf", "/scripts"]
