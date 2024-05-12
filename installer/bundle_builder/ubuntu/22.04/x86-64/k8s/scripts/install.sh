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
for pkg in containerd.io kubectl kubelet kubeadm; do
	dpkg --install "$BUNDLE_PATH/$pkg.deb"
    apt-mark hold $pkg
done

## starting containerd service
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd
