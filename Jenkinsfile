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
                        // extraVars: [
                        //   host: "${server_ip}",
                        // ],
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

    }

    post {
        always {
            echo 'CI/CD Pipeline Completed'
        }
    }
}
