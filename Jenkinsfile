pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-creds')
        TEST_SERVER_IP = ""
        PROD_SERVER_IP = ""
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/Raajitha96/myproject.git'
                sh 'chmod +x run-tests.sh'
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

        // Provision Test Server using Terraform
        stage('Provision Test Server (Terraform)') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            cd terraform/test
                            terraform init
                            terraform apply -auto-approve
                        """
                    }
                }
            }
        }

        stage('Retrieve Test Server IP') {
            steps {
                script {
                    // Ensure we're in the correct directory
                    dir('terraform/test') {
                        // Check if state file exists
                        sh "ls -l terraform.tfstate"

                        // Extract test server IP from Terraform output with color disabled
                        def tfOutput = sh(returnStdout: true, script: "terraform output -no-color -raw test_server_ip").trim()
                        
                        // Validate output
                        if (!tfOutput || tfOutput == 'null') {
                            error "Failed to retrieve the test server IP. The output was null or empty. Please check your Terraform configuration."
                        }

                        env.TEST_SERVER_IP = tfOutput
                        echo "Test Server IP: ${env.TEST_SERVER_IP}"

                        // Dynamically generate the inventory file for the test environment
                        writeFile file: 'ansible/inventory/test.ini', text: "[test]\ntest-server ansible_host=${env.TEST_SERVER_IP}\n"
                    }
                }
            }
        }

        stage('Configure Test Server (Ansible)') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbooks/test-server.yml',
                    inventory: 'ansible/inventory/test.ini'
                )
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sh "ansible-playbook -i ansible/inventory/test.ini ansible/playbooks/deploy.yml --extra-vars 'host=${env.TEST_SERVER_IP}'"
            }
        }

        stage('Automated Testing') {
            steps {
                sh './run-tests.sh'
            }
        }

        // Provision Production Server using Terraform
        stage('Provision Prod Server (Terraform)') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            cd terraform/prod
                            terraform init
                            terraform apply -auto-approve
                        """
                    }
                }
            }
        }

        stage('Retrieve Prod Server IP') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    // Ensure we're in the correct directory
                    dir('terraform/prod') {
                        // Check if state file exists
                        sh "ls -l terraform.tfstate"

                        // Extract prod server IP from Terraform output with color disabled
                        def tfOutput = sh(returnStdout: true, script: "terraform output -no-color -raw prod_server_ip").trim()
                        
                        // Validate output
                        if (!tfOutput || tfOutput == 'null') {
                            error "Failed to retrieve the prod server IP. The output was null or empty. Please check your Terraform configuration."
                        }

                        env.PROD_SERVER_IP = tfOutput
                        echo "Prod Server IP: ${env.PROD_SERVER_IP}"

                        // Dynamically generate the inventory file for the prod environment
                        writeFile file: 'ansible/inventory/prod.ini', text: "[prod]\nprod-server ansible_host=${env.PROD_SERVER_IP}\n"
                    }
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
                    inventory: 'ansible/inventory/prod.ini'
                )
            }
        }

        stage('Deploy to Prod Server') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh "ansible-playbook -i ansible/inventory/prod.ini ansible/playbooks/deploy.yml --extra-vars 'host=${env.PROD_SERVER_IP}'"
            }
        }
    }

    post {
        always {
            echo 'CI/CD Pipeline Completed'
        }
    }
}
