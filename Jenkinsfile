pipeline {
    agent any

    environment {
        IMAGE_NAME = "hshar/webapp"
        BUILD_TAG = "build-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Job1 : build') {
            steps {
                echo "Building docker image..."
                sh "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
            }
        }
        stage('Job2 : test') {
            steps {
                echo "Testing the application..."
                sh """
                    docker run -d --name temp-test -p 8082:80 ${IMAGE_NAME}:${BUILD_TAG}
                    sleep 3
                    curl -sI http://localhost:8082 | grep "200 OK" || (docker rm -f temp-test && exit 1)
                    docker rm -f temp-test
                """
            }
        }
        stage('Job3 : prod') {
            when {
                branch 'master'
            }
            steps {
                echo "Deploying to production..."
                sh """
                    docker rm -f prod-web || true
                    docker run -d --name prod-web -p 80:80 ${IMAGE_NAME}:${BUILD_TAG}
                """
            }
        }
    }
}
