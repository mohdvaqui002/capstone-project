#!/usr/bin/env bash
set -euo pipefail
systemctl stop jenkins
curl -fsSL https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.15.0/jenkins-plugin-manager-2.15.0.jar -o /tmp/jenkins-plugin-manager.jar
java -Xmx256m -jar /tmp/jenkins-plugin-manager.jar --war /usr/share/java/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins --plugins workflow-aggregator git credentials-binding timestamper
chown -R jenkins:jenkins /var/lib/jenkins/plugins
install -d -o jenkins -g jenkins /var/lib/jenkins/init.groovy.d
install -o jenkins -g jenkins -m 0600 /home/ubuntu/jenkins-bootstrap/secrets.json /var/lib/jenkins/bootstrap-secrets.json
install -o jenkins -g jenkins -m 0600 /home/ubuntu/jenkins-bootstrap/configure-jenkins.groovy /var/lib/jenkins/init.groovy.d/10-capstone.groovy
rm /home/ubuntu/jenkins-bootstrap/secrets.json
systemctl start jenkins
