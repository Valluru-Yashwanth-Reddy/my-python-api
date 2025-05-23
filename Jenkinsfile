pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'yashwanth2003'
        IMAGE_NAME = 'my-python-text'
    }

    stages {
        stage('📥 Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('🔧 Setup Environment') {
            steps {
                echo 'Setting up Python environment...'
                sh '''
                    python3 -m venv venv
                    ./venv/bin/python -m pip install --upgrade pip
                    ./venv/bin/pip install -r app/requirements.txt
                    ./venv/bin/pip install pytest coverage pylint flake8
                '''
            }
        }

        stage('📊 Code Quality - Linting') {
            steps {
                echo 'Running code quality checks...'
                sh '''
                    echo "Running Flake8..."
                    ./venv/bin/flake8 app/ --max-line-length=100 --ignore=E501,W503 || true

                    echo "Running Pylint..."
                    ./venv/bin/pylint app/ --disable=C0114,C0116,C0115 || true
                '''
            }
        }

        // stage('🧪 Unit Tests') {
        //     steps {
        //         echo 'Running unit tests...'
        //         sh '''
        //             cd app
        //             ../venv/bin/coverage run -m pytest tests/ -v
        //             ../venv/bin/coverage report
        //             ../venv/bin/coverage xml
        //         '''
        //     }
        // }

        stage('🔍 SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                script {
                    def scannerHome = tool 'SonarScanner' // Must match tool name configured in Jenkins
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        withSonarQubeEnv('SonarQube') {
                            sh "${scannerHome}/bin/sonar-scanner -Dsonar.login=${SONAR_TOKEN}"
                        }
                    }
                }
            }
        }

        stage('🚪 Quality Gate') {
            steps {
                echo 'Waiting for SonarQube Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        withSonarQubeEnv('SonarQube') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }
        }

        stage('🐳 Docker Build') {
            steps {
                echo 'Building Docker image...'
                script {
                    def imageTag = "${params.ENVIRONMENT}-${env.BUILD_NUMBER}"
                    def imageName = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}"

                    sh """
                        echo "Building image: ${imageName}:${imageTag}"
                        docker build -t ${imageName}:${imageTag} .
                        docker tag ${imageName}:${imageTag} ${imageName}:${params.ENVIRONMENT}-latest
                    """

                    env.IMAGE_TAG = imageTag
                    env.FULL_IMAGE_NAME = "${imageName}:${imageTag}"
                }
            }
        }

        stage('🔒 Container Security Scan') {
            steps {
                echo 'Scanning container for vulnerabilities...'
                script {
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy..."
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list
                            sudo apt-get update
                            sudo apt-get install -y trivy
                        fi

                        echo "Scanning image: ${FULL_IMAGE_NAME}"
                        trivy image --exit-code 0 --severity LOW,MEDIUM ${FULL_IMAGE_NAME}
                        trivy image --exit-code 1 --severity HIGH,CRITICAL ${FULL_IMAGE_NAME}
                    '''
                }
            }
        }

        stage('📤 Push to Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials',
                                                     usernameVariable: 'DOCKER_USERNAME',
                                                     passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo "Logging into Docker Hub..."
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                            echo "Pushing images..."
                            docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${ENVIRONMENT}-latest
                        '''
                    }
                }
            }
        }

        /* Uncomment when ready for deployment and health check
        
        stage('🚀 Deploy to Environment') {
            steps {
                echo "Deploying to ${env.ENVIRONMENT} environment..."
                script {
                    def targetHost = env.ENVIRONMENT == 'prod' ? env.PROD_EC2_HOST : env.DEV_EC2_HOST

                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key',
                                                       keyFileVariable: 'SSH_KEY')]) {
                        sh """
                            chmod 600 \$SSH_KEY
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no deploy/${env.ENVIRONMENT}/docker-compose.${env.ENVIRONMENT}.yml ec2-user@${targetHost}:/home/ec2-user/

                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no ec2-user@${targetHost} '
                                export DOCKER_REGISTRY=${DOCKER_REGISTRY}
                                export IMAGE_NAME=${IMAGE_NAME}
                                export BUILD_NUMBER=${BUILD_NUMBER}

                                docker-compose -f docker-compose.${ENVIRONMENT}.yml down || true
                                docker-compose -f docker-compose.${ENVIRONMENT}.yml pull
                                docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d
                                docker system prune -f
                            '
                        """
                    }
                }
            }
        }

        stage('🩺 Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    def targetHost = env.ENVIRONMENT == 'prod' ? env.PROD_EC2_HOST : env.DEV_EC2_HOST
                    def port = env.ENVIRONMENT == 'prod' ? '80' : '8000'

                    sh """
                        echo "Waiting for application to start..."
                        sleep 30

                        for i in {1..10}; do
                            if curl -f http://${targetHost}:${port}/health; then
                                echo "✅ Application is healthy!"
                                exit 0
                            fi
                            echo "⏳ Attempt \$i failed, retrying..."
                            sleep 10
                        done

                        echo "❌ Health check failed."
                        exit 1
                    """
                }
            }
        }
        */
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
