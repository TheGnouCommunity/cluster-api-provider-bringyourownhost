#!/bin/bash
echo "Uninstalling $K8S_VERSION from $BUNDLE_PATH..."

## removing Kubernetes
apt-mark unhold kubelet kubeadm kubectl
apt-get remove -y kubelet kubeadm kubectl
apt-get autoremove -y

## disabling and removing containerd
systemctl stop containerd
systemctl disable containerd
systemctl daemon-reload

rm -f /etc/systemd/system/containerd.service
rm -rf /opt/cni
rm -f /usr/local/sbin/runc
rm -rf /etc/containerd

## removing os configuration
tar tf "$BUNDLE_PATH/conf.tar" | xargs -n 1 echo '/' | sed 's/ //g' | grep -e "[^/]$" | xargs rm -f

## unloading kernal modules
modprobe -rq overlay
modprobe -r br_netfilter

## enable firewall
if command -v ufw >>/dev/null; then
	ufw enable
fi

## enable swap
swapon -a
sed -ri '/\sswap\s/s/^#?//' /etc/fstab
