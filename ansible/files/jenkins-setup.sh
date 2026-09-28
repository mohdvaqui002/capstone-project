#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq fontconfig openjdk-21-jre-headless docker.io git curl ca-certificates gnupg
install -d /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins.asc
echo 'deb [signed-by=/etc/apt/keyrings/jenkins.asc] https://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
apt-get update -qq
apt-get install -y -qq jenkins
usermod -aG docker jenkins
install -d /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/memory.conf <<'EOF'
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xms128m -Xmx512m"
EOF
systemctl daemon-reload
systemctl enable --now docker jenkins
systemctl restart jenkins
install -d /var/lib/capstone
touch /var/lib/capstone/jenkins-prepared
