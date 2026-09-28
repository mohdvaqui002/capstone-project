#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
NODE_IP="$1"
swapoff -a
sed -i '/\sswap\s/s/^/#/' /etc/fstab
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/kubernetes.conf
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null
apt-get update -qq
apt-get install -y -qq docker.io containerd curl ca-certificates gpg conntrack socat
mkdir -p /etc/containerd /etc/apt/keyrings
if ! test -f /etc/containerd/config.toml; then
  containerd config default > /etc/containerd/config.toml
fi
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd docker
systemctl restart containerd
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
printf 'KUBELET_EXTRA_ARGS=--node-ip=%s\n' "$NODE_IP" > /etc/default/kubelet
systemctl enable kubelet
systemctl restart kubelet
install -d /var/lib/capstone
touch /var/lib/capstone/node-prepared
