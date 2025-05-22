#!/bin/bash
set -e

echo "🚀 Deploying to Development Environment"

# Set variables
DOCKER_REGISTRY="your-dockerhub-username"  # Replace with your username
IMAGE_NAME="my-python-api"
DEV_HOST="your-dev-instance-ip"            # Replace with your dev IP
SSH_KEY="my-api-key.pem"

# Build and push image
echo "📦 Building Docker image..."
docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:dev-latest .

echo "📤 Pushing to registry..."
docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:dev-latest

# Deploy to EC2
echo "🚀 Deploying to EC2..."
scp -i ${SSH_KEY} -o StrictHostKeyChecking=no \
    deploy/dev/docker-compose.dev.yml \
    ec2-user@${DEV_HOST}:/home/ec2-user/

ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${DEV_HOST} '
    export DOCKER_REGISTRY='${DOCKER_REGISTRY}'
    export IMAGE_NAME='${IMAGE_NAME}'
    export BUILD_NUMBER=latest
    
    docker-compose -f docker-compose.dev.yml down || true
    docker-compose -f docker-compose.dev.yml pull
    docker-compose -f docker-compose.dev.yml up -d
'

echo "✅ Deployment completed!"
echo "🌐 Access your API at: http://${DEV_HOST}:8000"

