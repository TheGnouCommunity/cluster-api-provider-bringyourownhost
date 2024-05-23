#!/bin/bash
echo "Installing $K8S_VERSION from $BUNDLE_PATH..."

## disable swap
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

## disable firewall
if command -v ufw >>/dev/null; then
	ufw disable
fi

## load kernal modules
modprobe overlay
modprobe br_netfilter

## adding os configuration
tar -C / -xvf "$BUNDLE_PATH/conf.tar"
sysctl --system

# installing containerd
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io

## configuring containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/    sandbox_image = "registry.k8s.io\/pause:3.6"/    sandbox_image = "registry.k8s.io\/pause:3.9"/' /etc/containerd/config.toml

## starting containerd service
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd

## installing Kubernetes
K8S_VERSION_NUMBER=${K8S_VERSION#v}
K8S_SHORT_VERSION=${K8S_VERSION%.*}
apt-get install -y apt-transport-https
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$K8S_SHORT_VERSION/deb/Release.key" | gpg --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_SHORT_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=$K8S_VERSION_NUMBER-\* kubeadm=$K8S_VERSION_NUMBER-\* kubectl=$K8S_VERSION_NUMBER-\*
apt-mark hold kubelet kubeadm kubectl

## enable the kubelet service before running kubeadm
systemctl enable --now kubelet