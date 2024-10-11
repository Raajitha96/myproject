pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "financeapp:latest"
        DOCKER_REGISTRY = "docker.io/teja694"
        // Docker credentials (stored in Jenkins credentials)
        DOCKER_CREDENTIALS = credentials('dockerhub-creds') // Using the correct Jenkins credential ID
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/Raajitha96/myproject.git'
                sh 'chmod +x run-tests.sh'  // Make the script executable
            }
        }
        
        stage('Build & Unit Test') {
            steps {
                sh 'mvn clean install'
                sh 'mvn test'
            }
        }
        
        stage('Docker Login') {
            steps {
                script {
                    // Log into the Docker registry using stored credentials
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo '${DOCKER_PASSWORD}' | docker login -u '${DOCKER_USERNAME}' --password-stdin ${DOCKER_REGISTRY}"
                    }
                }
            }
        }

        stage('Package & Dockerize') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                    sh "docker tag ${DOCKER_IMAGE} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}"
                    sh "docker 
