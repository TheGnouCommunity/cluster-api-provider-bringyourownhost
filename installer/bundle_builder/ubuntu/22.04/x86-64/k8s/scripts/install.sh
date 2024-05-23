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
wget https://github.com/containerd/containerd/releases/download/v1.7.17/containerd-1.7.17-linux-amd64.tar.gz -P /tmp/
tar Cxzvf /usr/local /tmp/containerd-1.7.17-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd

wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64 -P /tmp/
install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc

wget https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz -P /tmp/
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-amd64-v1.5.0.tgz

## configuring containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/    sandbox_image = "registry.k8s.io\/pause:3.8"/    sandbox_image = "registry.k8s.io\/pause:3.9"/' /etc/containerd/config.toml

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