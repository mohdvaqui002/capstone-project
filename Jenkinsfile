pipeline {
  agent any
  options {
    disableConcurrentBuilds()
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  triggers {
    pollSCM('H/2 * * * *')
    cron('TZ=Asia/Kolkata\nH 9 25 * *')
  }
  environment {
    IMAGE_NAME = 'mohdvaqui002/capstone-project'
    KUBECONFIG = '/var/lib/jenkins/.kube/config'
  }
  stages {
    stage('Build') {
      steps {
        script { env.IMAGE_TAG = "${env.BUILD_NUMBER}-${sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()}" }
        sh 'docker build --pull -t "$IMAGE_NAME:$IMAGE_TAG" .'
      }
    }
    stage('Test') {
      steps {
        sh '''#!/bin/bash
set -euo pipefail
name="capstone-test-${BUILD_NUMBER}"
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$name" -p 127.0.0.1::80 "$IMAGE_NAME:$IMAGE_TAG"
port=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' "$name")
curl --fail --retry 10 --retry-connrefused --retry-delay 2 "http://127.0.0.1:$port/" | grep -q 'Hello world!'
curl --fail "http://127.0.0.1:$port/images/github3.jpg" -o /dev/null
bash scripts/is-release-day.sh 2026-10-25
if bash scripts/is-release-day.sh 2026-10-24; then exit 1; fi
if bash scripts/is-release-day.sh 2026-10-26; then exit 1; fi
'''
      }
    }
    stage('Push tested image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_TOKEN')]) {
          sh '''#!/bin/bash
set -euo pipefail
set +x
export DOCKER_CONFIG=$(mktemp -d)
trap 'rm -rf "$DOCKER_CONFIG"' EXIT
printf '%s' "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
docker push "$IMAGE_NAME:$IMAGE_TAG"
docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_NAME:$IMAGE_TAG" > image-digest.txt
'''
        }
        archiveArtifacts artifacts: 'image-digest.txt', fingerprint: true
      }
    }
    stage('Release on the 25th') {
      when { expression { sh(script: 'bash scripts/is-release-day.sh', returnStatus: true) == 0 } }
      steps { sh 'bash scripts/deploy.sh' }
    }
  }
  post {
    always { sh 'docker image prune -f --filter "until=24h" >/dev/null || true' }
  }
}
