pipeline {
    agent any

    environment {
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
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                    }
                }
            }
        }

        stage('Package & Dockerize') {
            steps {
                script {
                    sh "docker build -t financeapp ."
                    sh "docker tag financeapp teja694/financeapp:latest"
                    sh "docker push teja694/financeapp:latest"
                }
            }
        }
        
        stage('Provision Test Server (Terraform)') {
            steps {
                dir('terraform/test') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Retrieve Test Server IP') {
            steps {
                script {
                    // Extract test server IP from Terraform output
                    TEST_SERVER_IP = sh(returnStdout: true, script: "terraform output -raw test_server_ip").trim()
                    echo "Test Server IP: ${TEST_SERVER_IP}"
                    
                    // Dynamically generate the inventory file for the test environment
                    writeFile file: 'ansible/inventory/test', text: "[test]\ntest-server ansible_host=${TEST_SERVER_IP}\n"
                }
            }
        }

        stage('Configure Test Server (Ansible)') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbooks/test-server.yml',
                    inventory: 'ansible/inventory/test'
                )
            }
        }
        
        stage('Deploy to Test Server') {
            steps {
                sh 'ansible-playbook -i ansible/inventory/test ansible/playbooks/deploy.yml --extra-vars "host=${TEST_SERVER_IP}"'
            }
        }

        stage('Automated Testing') {
            steps {
                sh './run-tests.sh'
            }
        }

        stage('Provision Prod Server (Terraform)') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                dir('terraform/prod') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Retrieve Prod Server IP') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    // Extract prod server IP from Terraform output
                    PROD_SERVER_IP = sh(returnStdout: true, script: "terraform output -raw prod_server_ip").trim()
                    echo "Prod Server IP: ${PROD_SERVER_IP}"
                    
                    // Dynamically generate the inventory file for the prod environment
                    writeFile file: 'ansible/inventory/prod', text: "[prod]\nprod-server ansible_host=${PROD_SERVER_IP}\n"
                }
            }
        }

        stage('Configure Prod Server (Ansible)') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbooks/prod-server.yml',
                    inventory: 'ansible/inventory/prod'
                )
            }
        }
        
        stage('Deploy to Prod Server') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh 'ansible-playbook -i ansible/inventory/prod ansible/playbooks/deploy.yml --extra-vars "host=${PROD_SERVER_IP}"'
            }
        }
    }

    post {
        always {
            echo 'CI/CD Pipeline Completed'
        }
    }
}
