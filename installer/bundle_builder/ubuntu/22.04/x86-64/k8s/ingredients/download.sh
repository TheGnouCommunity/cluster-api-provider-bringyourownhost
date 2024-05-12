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

echo Configure apt repository for containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo Configure apt repository for Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_MAJOR_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_MAJOR_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

echo Update apt package index, install kubelet, kubeadm and kubectl, and other dependencies
apt-get update
apt-get download {kubelet,kubeadm,kubectl}:$ARCH=$KUBERNETES_VERSION
apt-get download kubernetes-cni:$ARCH=$KUBERNETES_CNI_VERSION
apt-get download cri-tools:$ARCH=$CRI_TOOLS_VERSION
apt-get download containerd.io:$ARCH=$CONTAINERD_VERSION
