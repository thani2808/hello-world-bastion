pipeline {
    agent any

    environment {
        IMAGE_NAME = "hello-world-bastion-app"
        DOCKERHUB_REPO = "thanigai2808/hello-world-bastion-app"
        CONTAINER_NAME = "hello-world-bastion-container"
        DOCKER_PORT = "9002"
        HOST_PORT = "9002"
        BASTION_IP = "ec2-3-111-111-111.compute-1.amazonaws.com"
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

        stage('Push Docker Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    bat """
                        echo Logging in to DockerHub...
                        echo %DOCKERHUB_PASS% | docker login -u %DOCKERHUB_USER% --password-stdin
                        docker tag ${IMAGE_NAME} ${DOCKERHUB_REPO}
                        docker push ${DOCKERHUB_REPO}
                        docker logout
                    """
                }
            }
        }

        stage('SSH to Bastion and Run Container') {
            steps {
                echo "🚀 Connecting to Bastion EC2 and deploying Docker container..."
                sshagent(['bastion-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${BASTION_USER}@${BASTION_IP} << 'EOF'
                            echo "🔧 Cleaning old Docker container..."
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                            docker rmi ${DOCKERHUB_REPO} || true

                            echo "📥 Pulling latest image from DockerHub..."
                            docker pull ${DOCKERHUB_REPO}

                            echo "🚀 Running container..."
                            docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${DOCKER_PORT} ${DOCKERHUB_REPO}
                        EOF
                    """
                }
            }
        }

        stage('Health Check on Bastion') {
            steps {
                echo "🩺 Running health check..."
                sshagent(['bastion-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${BASTION_USER}@${BASTION_IP} << 'EOF'
                            echo "⏳ Waiting for container to be healthy..."
                            retries=5
                            for i in \$(seq 1 \$retries); do
                                if curl -s http://localhost:${HOST_PORT} > /dev/null; then
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
