#!/bin/bash
set -euxo pipefail
# This script needs to be ran as root

# Detect system architecture
ARCH=$(uname -m)
case $ARCH in
  x86_64)
    CNI_ARCH="amd64"
    ;;
  aarch64)
    CNI_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Detected architecture: $ARCH (using CNI arch: $CNI_ARCH)"

# Kubernetes Variable Declaration
KUBERNETES_VERSION="v1.33"
CRIO_VERSION="v1.33"

# Disable swap
swapoff -a

# Keeps the swap off during reboot
(
  crontab -l 2>/dev/null
  echo "@reboot /sbin/swapoff -a"
) | crontab - || true
apt-get update -y

# Create the .conf file to load the modules at bootup
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

apt-get update -y
apt-get install -y software-properties-common curl apt-transport-https ca-certificates gpg

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --batch --yes --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt-get update -y
apt-get install -y cri-o

systemctl daemon-reload
systemctl enable crio --now
systemctl start crio.service

echo "CRI runtime installed successfully"

# Install kubelet, kubectl, and kubeadm
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
  gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
  tee /etc/apt/sources.list.d/kubernetes.list

curl -LO https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-${CNI_ARCH}-v1.7.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-${CNI_ARCH}-v1.7.1.tgz

apt-get update -y
apt-get install -y kubelet kubeadm

kubeadm config images pull --cri-socket=/var/run/crio/crio.sock
