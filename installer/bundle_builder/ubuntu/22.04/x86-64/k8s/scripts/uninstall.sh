#!/bin/bash
## disabling containerd service
systemctl stop containerd
systemctl disable containerd
systemctl daemon-reload

rm -f /etc/containerd/config.toml

## removing deb packages
for pkg in kubeadm cri-tools kubelet kubernetes-cni kubectl containerd.io; do
	dpkg --purge $pkg
done

## removing os configuration
tar tf "$BUNDLE_PATH/conf.tar" | xargs -n 1 echo '/' | sed 's/ //g' | grep -e "[^/]$" | xargs rm -f

## remove kernal modules
modprobe -rq overlay
modprobe -r br_netfilter

## enable firewall
if command -v ufw >>/dev/null; then
	ufw enable
fi

## enable swap
swapon -a
sed -ri '/\sswap\s/s/^#?//' /etc/fstab
