pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-creds')
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
                        // Extract test server IP from Terraform output
                        def tfOutputTest = sh(returnStdout: true, script: "terraform output -no-color -raw test_server_ip").trim()

                        echo "Test Server IP: ${tfOutputTest}"

                        sh "mkdir -p ../../ansible/inventory"

                        def data = "[test_server]\ntest-server ansible_host=${tfOutputTest}\n"
                        writeFile(file: '../../ansible/inventory/test.ini', text: data)

                        def server = "${tfOutputTest}"
                        writeFile(file: '../../test-server', text: server)
                    }
                }
            }
        }

        stage('Configure Test Server (Ansible)') {
              steps {
                    ansiblePlaybook(
                        playbook: 'ansible/playbooks/test-server.yml',
                        inventory: 'ansible/inventory/test.ini',
                        credentialsId: 'ansible_ssh_private_key_file',
                        hostKeyChecking: false,
                        disableHostKeyChecking: true
                    )
            }
        }

        stage('Deploy to Test Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    script {
                      def server_ip = readFile('test-server').trim()
                      echo "Server IP: ${server_ip}"
                    }
                    ansiblePlaybook(
                        playbook: 'ansible/playbooks/deploy.yml',
                        inventory: 'ansible/inventory/test.ini',
                        extraVars: [
                          username: "${DOCKER_USERNAME}",
                          password: "${DOCKER_PASSWORD}",
                        ],
                        credentialsId: 'ansible_ssh_private_key_file',
                        hostKeyChecking: false,
                        disableHostKeyChecking: true
                    )
                }
            }
        }

        stage('Automated Testing') {
            steps {
                script {
                    def server_ip = readFile('test-server').trim()
                    echo "Server IP: ${server_ip}"
                    sh "./run-tests.sh ${server_ip}"
                }
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

        stage('Retrieve Production Server IP') {
            steps {
                script {
                    // Ensure we're in the correct directory
                    dir('terraform/prod') {
                        // Extract production server IP from Terraform output
                        def tfOutputProd = sh(returnStdout: true, script: "terraform output -no-color -raw prod_server_ip").trim()

                        echo "Production Server IP: ${tfOutputProd}"

                        sh "mkdir -p ../../ansible/inventory"

                        def data = "[prod_server]\nprod-server ansible_host=${tfOutputProd}\n"
                        writeFile(file: '../../ansible/inventory/prod.ini', text: data)

                        def server = "${tfOutputProd}"
                        writeFile(file: '../../prod-server', text: server)
                    }
                }
            }
        }

        stage('Configure Production Server (Ansible)') {
              steps {
                    ansiblePlaybook(
                        playbook: 'ansible/playbooks/prod-server.yml',
                        inventory: 'ansible/inventory/prod.ini',
                        credentialsId: 'ansible_ssh_private_key_file',
                        hostKeyChecking: false,
                        disableHostKeyChecking: true
                    )
            }
        }

        stage('Deploy to Production Server') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    script {
                      def server_ip = readFile('prod-server').trim()
                      echo "Production Server IP: ${server_ip}"
                    }
                    ansiblePlaybook(
                        playbook: 'ansible/playbooks/deploy.yml',
                        inventory: 'ansible/inventory/prod.ini',
                        extraVars: [
                          username: "${DOCKER_USERNAME}",
                          password: "${DOCKER_PASSWORD}",
                        ],
                        credentialsId: 'ansible_ssh_private_key_file',
                        hostKeyChecking: false,
                        disableHostKeyChecking: true
                    )
                }
            }
        }
    }

    post {
        always {
            echo 'CI/CD Pipeline Completed'
        }
    }
}
