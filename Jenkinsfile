pipeline {
    agent {
        docker {
            image 'node:18-alpine' 
            args '-u root' // Run as root to avoid permission issues
        }
    }
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'yourusername/sample-app'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        
        // Example environment-specific deployment URLs
        DEV_DEPLOY_URL = 'dev-server.example.com'
        STAGING_DEPLOY_URL = 'staging-server.example.com'
        PROD_DEPLOY_URL = 'prod-server.example.com'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Checked out source code'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
                echo 'Build completed'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
                echo 'Tests completed'
            }
            post {
                always {
                    junit 'test-results/*.xml'
                }
            }
        }
        
        stage('Static Analysis') {
            steps {
                sh 'npm run lint'
                echo 'Static analysis completed'
            }
        }
        
        stage('Package Docker Image') {
            agent {
                docker {
                    image 'docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    echo "Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('Publish to Registry') {
            agent {
                docker {
                    image 'docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        // Also push as latest
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                    echo "Docker image pushed to registry"
                }
            }
        }
        
        stage('Deploy to Development') {
            steps {
                script {
                    echo "Deploying to Development environment: ${DEV_DEPLOY_URL}"
                    // Deployment script or command here
                    sh './scripts/deploy.sh development ${DOCKER_IMAGE}:${DOCKER_TAG}'
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    echo "Running integration tests against Development environment"
                    sh './scripts/integration-tests.sh'
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve deployment to Staging?'
                }
                script {
                    echo "Deploying to Staging environment: ${STAGING_DEPLOY_URL}"
                    sh './scripts/deploy.sh staging ${DOCKER_IMAGE}:${DOCKER_TAG}'
                }
            }
        }
        
        stage('Acceptance Tests') {
            steps {
                script {
                    echo "Running acceptance tests against Staging environment"
                    sh './scripts/acceptance-tests.sh'
                }
            }
        }
        
        stage('Deploy to Production') {
            steps {
                timeout(time: 2, unit: 'HOURS') {
                    input message: 'Approve deployment to Production?'
                }
                script {
                    echo "Deploying to Production environment: ${PROD_DEPLOY_URL}"
                    sh './scripts/deploy.sh production ${DOCKER_IMAGE}:${DOCKER_TAG}'
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    echo "Running smoke tests against Production environment"
                    sh './scripts/smoke-tests.sh'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
            // Send notifications on failure
            // mail to: 'team@example.com', subject: 'Pipeline Failed', body: "Pipeline ${env.JOB_NAME} failed. Check ${env.BUILD_URL}"
        }
        always {
            // Clean workspace
            cleanWs()
        }
    }
}