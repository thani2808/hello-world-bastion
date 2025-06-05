pipeline {
    agent any

    environment {
        IMAGE_NAME = "hello-world-bastion-app"
        DOCKERHUB_REPO = "thanigai2808/hello-world-bastion-app"
        CONTAINER_NAME = "hello-world-bastion-container"
        DOCKER_PORT = "9002"
        HOST_PORT = "9002"
        BASTION_IP = "13.201.31.196"
        BASTION_USER = "ubuntu"
    }

    stages {
        stage('Clone the Repo') {
            steps {
                echo '🔄 Cloning the repository...'
                deleteDir()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/feature']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:thani2808/hello-world-bastion.git',
                        credentialsId: 'private-key-jenkins'
                    ]]
                ])
            }
        }

        stage('Build JAR') {
            steps {
                bat 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    if (!fileExists('Dockerfile')) {
                        error "❌ Dockerfile not found in project root!"
                    }
                }
                bat "docker build -t ${IMAGE_NAME} ."
            }
        }

	stage('Tag & Push Docker Image to DockerHub') {
	    steps {
	        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
	            bat """
	                echo Logging in to DockerHub...
	                echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin || exit /b

	                echo Tagging image...
	                docker tag ${IMAGE_NAME} ${DOCKERHUB_REPO}:latest || exit /b

	                echo Pushing image to DockerHub...
	                docker push ${DOCKERHUB_REPO}:latest || exit /b

	                echo Logging out from DockerHub...
	                docker logout
	            """
	        }
	    }
	}

        stage('SSH to Bastion and Run Container') {
            steps {
                echo "🚀 Connecting to Bastion EC2 and deploying Docker container..."
		withCredentials([sshUserPrivateKey(credentialsId: 'testing', keyFileVariable: "keyf", usernameVariable: 'username')]) {
                    sh """
			ssh-keyscan -H ${BASTION_IP} >> ~/.ssh/known_hosts
                        ssh -i $keyf ${username}@${BASTION_IP} << EOF
echo "🔧 Cleaning old Docker container..."
docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true
docker rmi ${DOCKERHUB_REPO}:latest || true
echo "📥 Pulling latest image from DockerHub..."
docker pull ${DOCKERHUB_REPO}:latest
echo "🚀 Running container..."
docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${DOCKER_PORT} ${DOCKERHUB_REPO}:latest
EOF
			"""
		}
            }
        }


	stage('Health Check on Bastion') {
    		steps {
        		echo "🩺 Running health check..."
        		withCredentials([sshUserPrivateKey(credentialsId: 'testing', keyFileVariable: "keyf", usernameVariable: 'username')]) {
            	sh """
                	ssh-keyscan -H ${BASTION_IP} >> ~/.ssh/known_hosts
                	ssh -i $keyf $username@${BASTION_IP} << EOF
#!/bin/bash
set -x
echo "⏳ Waiting for container to be healthy..."
retries=10
for i in \$(seq 1 \$retries); do
RESPONSE_CODE=`curl -o /dev/null -s -w "%{http_code}\n" http://localhost:${DOCKER_PORT}`
if [ "$RESPONSE_CODE" == 200 ]; then
echo "✅ App is running!"
exit 0
else
echo "Retry \$i/\$retries - App not ready yet."
sleep 5
fi
done
echo "❌ App did not start properly."
exit 1
EOF
            """
        }
    }
}

        stage('Success Confirmation') {
            steps {
                echo '✅ Docker image deployed successfully on bastion EC2!'
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
        always {
            echo '📋 Pipeline execution completed.'
        }
    }
}
