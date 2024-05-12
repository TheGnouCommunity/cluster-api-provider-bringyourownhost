#!/bin/bash

# Copyright 2021 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

echo Update the apt package index and install packages needed to use the Kubernetes apt repository
apt-get update
DEBIAN_FRONTEND=noninteractive \
apt-get install -y \
                --no-install-recommends \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg

echo Download containerd
curl -LOJR https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/cri-containerd-cni-${CONTAINERD_VERSION}-linux-amd64.tar.gz

echo Configure apt repository for Kubernetes
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_MAJOR_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_MAJOR_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

echo Update apt package index, install kubelet, kubeadm and kubectl
apt-get update
apt-get download {kubelet,kubeadm,kubectl}:$ARCH=$KUBERNETES_VERSION
apt-get download kubernetes-cni:$ARCH=1.1.1-2.1
apt-get download cri-tools:$ARCH=1.25.0-1.1
