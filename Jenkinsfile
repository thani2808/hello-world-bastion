pipeline {
    agent any

    environment {
        IMAGE_NAME = "hello-world-bastion-app"
        DOCKERHUB_REPO = "thani2808/hello-world-bastion-app"
        CONTAINER_NAME = "hello-world-bastion-container"
        DOCKER_PORT = "9002"
        HOST_PORT = "9002"
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

        stage('Debug Workspace') {
            steps {
                echo '📂 Listing workspace contents...'
                bat 'dir'
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

        stage('Tag and Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
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

        stage('Clean Local Container & Image') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    bat """
                        docker stop ${CONTAINER_NAME} 2>nul || exit 0
                        docker rm ${CONTAINER_NAME} 2>nul || exit 0
                        docker rmi ${DOCKERHUB_REPO} 2>nul || exit 0
                        docker rmi ${IMAGE_NAME} 2>nul || exit 0
                    """
                }
            }
        }

        stage('Run Container from DockerHub') {
            steps {
                bat """
                    docker pull ${DOCKERHUB_REPO}
                    docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${DOCKER_PORT} ${DOCKERHUB_REPO}
                """
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def retries = 5
                    def success = false
                    for (int i = 0; i < retries; i++) {
                        def result = bat(
                            script: "curl --fail --silent http://localhost:${HOST_PORT}",
                            returnStatus: true
                        )
                        if (result == 0) {
                            echo "✅ Spring Boot app is up!"
                            success = true
                            break
                        } else {
                            echo "⏳ Waiting for Spring Boot app... Retry ${i + 1}/${retries}"
                            sleep(time: 5, unit: 'SECONDS')
                        }
                    }
                    if (!success) {
                        error "❌ Spring Boot app did not become healthy in time."
                    }
                }
            }
        }

        stage('Success Confirmation') {
            steps {
                echo '✅ Docker image pushed to DockerHub and deployed successfully from remote!'
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
        always {
            echo '📝 Pipeline execution finished.'
        }
    }
}
