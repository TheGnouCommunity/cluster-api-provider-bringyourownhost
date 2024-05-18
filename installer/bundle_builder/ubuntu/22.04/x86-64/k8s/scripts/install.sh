#!/bin/bash
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

## installing deb packages
for pkg in containerd.io kubectl kubernetes-cni kubelet cri-tools kubeadm; do
	dpkg --install "$BUNDLE_PATH/$pkg.deb"
    apt-mark hold $pkg
done

## configuring containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/    sandbox_image = "registry.k8s.io\/pause:3.6"/    sandbox_image = "registry.k8s.io\/pause:3.9"/' /etc/containerd/config.toml

## starting containerd service
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd

## enable the kubelet service before running kubeadm
systemctl enable --now kubelet