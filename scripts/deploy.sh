#!/bin/bash
set -e

# Deployment script for CI/CD pipeline
# Usage: ./deploy.sh <environment> <docker_image>

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment> <docker_image>"
    echo "Example: $0 development yourusername/sample-app:latest"
    exit 1
fi

ENVIRONMENT=$1
DOCKER_IMAGE=$2
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_LOG="deploy_${ENVIRONMENT}_${TIMESTAMP}.log"

echo "Starting deployment to ${ENVIRONMENT} environment" | tee -a $DEPLOY_LOG
echo "Using Docker image: ${DOCKER_IMAGE}" | tee -a $DEPLOY_LOG
echo "Deployment timestamp: ${TIMESTAMP}" | tee -a $DEPLOY_LOG

# Set environment-specific variables
case $ENVIRONMENT in
    development)
        SERVER="dev-server.example.com"
        SERVER_PORT="8080"
        SERVER_USER="deploy"
        ;;
    staging)
        SERVER="staging-server.example.com"
        SERVER_PORT="8080"
        SERVER_USER="deploy"
        ;;
    production)
        SERVER="prod-server.example.com"
        SERVER_PORT="80"
        SERVER_USER="deploy"
        ;;
    *)
        echo "Error: Invalid environment '${ENVIRONMENT}'" | tee -a $DEPLOY_LOG
        echo "Valid environments: development, staging, production" | tee -a $DEPLOY_LOG
        exit 1
        ;;
esac

echo "Target server: ${SERVER}" | tee -a $DEPLOY_LOG

# Function to check if deployment was successful
check_deployment() {
    local max_attempts=10
    local attempt=1
    local sleep_time=6
    
    echo "Checking deployment status..." | tee -a $DEPLOY_LOG
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..." | tee -a $DEPLOY_LOG
        
        # Check if application is healthy using health endpoint
        if curl -s -f "http://${SERVER}:${SERVER_PORT}/health" > /dev/null; then
            echo "Deployment successful! Application is healthy." | tee -a $DEPLOY_LOG
            return 0
        else
            echo "Application not healthy yet, waiting ${sleep_time} seconds..." | tee -a $DEPLOY_LOG
            sleep $sleep_time
            attempt=$((attempt+1))
        fi
    done
    
    echo "Deployment check failed after $max_attempts attempts." | tee -a $DEPLOY_LOG
    return 1
}

# Deploy using SSH and Docker
echo "Deploying to ${SERVER}..." | tee -a $DEPLOY_LOG

# The following command would be executed in a real environment
# Replace with actual SSH key and authentication method in production
echo "ssh ${SERVER_USER}@${SERVER} <<EOF
    docker pull ${DOCKER_IMAGE}
    docker stop app-container 2>/dev/null || true
    docker rm app-container 2>/dev/null || true
    docker run -d --name app-container -p ${SERVER_PORT}:3000 ${DOCKER_IMAGE}
    docker system prune -f
EOF" | tee -a $DEPLOY_LOG

# In this demo, we'll simulate the deployment
echo "Simulating deployment (remove this in real environment)" | tee -a $DEPLOY_LOG
sleep 5

# Check deployment status
if check_deployment; then
    echo "Deployment to ${ENVIRONMENT} completed successfully!" | tee -a $DEPLOY_LOG
    exit 0
else
    echo "Deployment to ${ENVIRONMENT} failed!" | tee -a $DEPLOY_LOG
    exit 1
fi