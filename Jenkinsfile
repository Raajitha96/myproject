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

        stage('Retrieve Test Server IP') {
            steps {
                script {
                    // Ensure we're in the correct directory
                    dir('terraform/test') {
                        // Check if state file exists

                        // Extract test server IP from Terraform output with color disabled
                        def tfOutputTest = sh(returnStdout: true, script: "echo 44.222.177.151").trim()


                        echo "Test Server IP: ${tfOutputTest}"

                        sh "mkdir -p ../../ansible/inventory"

                        def data = "[test_server]\ntest-server ansible_host=${tfOutputTest}\n"
                        writeFile(file: '../../ansible/inventory/test.ini', text: data)
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
                    ansiblePlaybook(
                        playbook: 'ansible/playbooks/deploy.yml',
                        inventory: 'ansible/inventory/test.ini',
                        extraVars: [
                          host: '${tfOutputTest}',
                        ],
                        credentialsId: 'ansible_ssh_private_key_file',
                        hostKeyChecking: false,
                        disableHostKeyChecking: true
                    )
            }
        }

        stage('Automated Testing') {
            steps {
                sh './run-tests.sh'
            }
        }

    }

    post {
        always {
            echo 'CI/CD Pipeline Completed'
        }
    }
}