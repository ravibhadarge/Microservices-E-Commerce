import os

services = ['adservice', 'cartservice', 'checkoutservice', 'currencyservice',
            'emailservice', 'frontend', 'loadgenerator', 'paymentservice',
            'productcatalogservice', 'recommendationservice', 'shippingservice']

template = '''pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'ravibhadarge'
        SERVICE_NAME = 'SERVICE_NAME_PLACEHOLDER'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "${DOCKERHUB_USERNAME}/ecommerce-dev-${SERVICE_NAME}:${IMAGE_TAG}"
                    def latestImage = "${DOCKERHUB_USERNAME}/ecommerce-dev-${SERVICE_NAME}:latest"

                    dir("src/${SERVICE_NAME}") {
                        sh """
                            echo "Building Docker image: ${imageName}"
                            docker build -t ${imageName} .
                            docker tag ${imageName} ${latestImage}
                        """
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "${DOCKERHUB_USERNAME}/ecommerce-dev-${SERVICE_NAME}:${IMAGE_TAG}"
                    def latestImage = "${DOCKERHUB_USERNAME}/ecommerce-dev-${SERVICE_NAME}:latest"

                    sh """
                        echo \\$DOCKERHUB_CREDENTIALS_PSW | docker login -u \\$DOCKERHUB_CREDENTIALS_USR --password-stdin
                        docker push ${imageName}
                        docker push ${latestImage}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                    aws eks update-kubeconfig --region us-east-1 --name ecommerce-dev-cluster
                    kubectl set image deployment/${SERVICE_NAME} ${SERVICE_NAME}=${DOCKERHUB_USERNAME}/ecommerce-dev-${SERVICE_NAME}:${IMAGE_TAG} -n dev || echo "Deployment update skipped"
                """
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
        }
        success {
            echo "Successfully built and pushed ${SERVICE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "Build failed for ${SERVICE_NAME}"
        }
    }
}'''

for service in services:
    content = template.replace('SERVICE_NAME_PLACEHOLDER', service)
    filepath = os.path.join(service, 'Jenkinsfile')
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Created: {filepath}")

print(f"\nTotal: {len(services)} Jenkinsfiles created")
