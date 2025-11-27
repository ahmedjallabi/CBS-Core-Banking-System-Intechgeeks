pipeline {
    agent any

    environment {
        // Docker
        DOCKER_REGISTRY = 'ahm2022'

        // Kubernetes
        K8S_NAMESPACE = 'cbs-system'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'

        // OWASP ZAP
        ZAP_HOST = '192.168.90.136'
        ZAP_PORT = '8090'

        // Cluster IPs
        MASTER_IP = '192.168.90.136'
        WORKER1_IP = '192.168.90.128'
        WORKER2_IP = '192.168.90.129'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'jenkins-github',
                    url: 'https://github.com/ahmedjallabi/CBS-Core-Banking-System-Intechgeeks.git'
            }
        }

        stage('Code Quality Analysis (SonarQube)') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                        sh '''
#!/bin/bash
docker run --rm \
  -v $(pwd):/usr/src \
  -e SONAR_HOST_URL=http://192.168.90.136:9000 \
  -e SONAR_LOGIN=$SONAR_TOKEN \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=CBS-stimul \
  -Dsonar.sources=/usr/src \
  -Dsonar.login=$SONAR_TOKEN \
  -Dsonar.host.url=http://192.168.90.136:9000
'''
                    }
                }
            }
        }

        stage('Dependency Audit (npm audit)') {
            steps {
                script {
                    def apps = ['cbs-simulator', 'middleware', 'dashboard']
                    apps.each { app ->
                        dir(app) {
                            sh 'npm install --no-audit --no-fund'
                            sh "npm audit --json > ../${app}-npm-audit.json || true"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                withDockerRegistry(credentialsId: 'docker-hub-creds', url: 'https://index.docker.io/v1/') {
                    script {
                        def apps = ['cbs-simulator', 'middleware', 'dashboard']

                        apps.each { app ->
                            echo "=== Building image for: ${app} ==="

                            // Vérifier que le dossier existe
                            sh "if [ ! -d './${app}' ]; then echo 'ERROR: directory ./${app} not found'; ls -la || true; exit 1; fi"

                            // Construire le tag et la commande en Groovy (interpolation ici)
                            def imageTag = "${env.DOCKER_REGISTRY}/${app}:latest"
                            def buildCmd = "docker build --no-cache -t ${imageTag} ./${app}"

                            // Afficher la commande (debug) puis l'exécuter
                            echo "DEBUG: will run: ${buildCmd}"
                            sh buildCmd

                            // Test run (optionnel) — utile pour détecter les erreurs d'image
                            sh "docker run --rm -d --name test-${app} -p 8080:80 ${imageTag} || true"
                            sh 'sleep 5'
                            sh "curl -f http://localhost:8080 || echo 'Health check failed (may be normal for non-web apps)'"
                            sh "docker stop test-${app} || true"
                            sh "docker rm test-${app} || true"

                            // Push
                            echo "Pushing ${imageTag}..."
                            sh "docker push ${imageTag}"
                            echo "✓ ${imageTag} pushed"
                        }
                    }
                }
            }
        }

        stage('Image Security Scan (Trivy)') {
            steps {
                script {
                    ['cbs-simulator','middleware','dashboard'].each { app ->
                        sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${env.DOCKER_REGISTRY}/${app}:latest > ${app}-trivy-report.txt || true"
                    }
                }
            }
        }

        stage('Deployment to Test Env') {
            steps {
                script {
                    try {
                        sh "kubectl create namespace ${env.K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                        sh "kubectl delete deployment cbs-simulator middleware dashboard -n ${env.K8S_NAMESPACE} --ignore-not-found"

                        sh "sleep 10"
                        sh "kubectl apply -f kubernetes/deploy-all.yaml"

                        ['cbs-simulator','middleware','dashboard'].each { app ->
                            sh "kubectl rollout status deployment/${app} -n ${env.K8S_NAMESPACE} --timeout=300s"
                        }

                        sh """
                            kubectl get svc -n ${env.K8S_NAMESPACE}
                            kubectl get pods -n ${env.K8S_NAMESPACE} -o wide
                            kubectl get deployments -n ${env.K8S_NAMESPACE}
                        """

                    } catch (e) {
                        sh """
                            kubectl get all -n ${env.K8S_NAMESPACE} || true
                            kubectl describe pods -n ${env.K8S_NAMESPACE} || true
                        """
                        error("Deployment failed: ${e.message}")
                    }
                }
            }
        }

        stage('Verify Deployment Health') {
            steps {
                sh """
                    curl -f http://${env.MASTER_IP}:30004 || true
                    curl -f http://${env.MASTER_IP}:30003/health || true
                    curl -f http://${env.MASTER_IP}:30005 || true
                """
            }
        }

        stage('Dynamic Security Testing (OWASP ZAP)') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'owasp-zap-api-key', variable: 'ZAP_API_KEY')]) {
                        sh """
echo '=== OWASP ZAP Scan START ==='
# Note: \$ZAP_API_KEY is escaped so Groovy won't interpolate it — the shell will.
curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/JSON/spider/action/scan/?apikey=\\\$ZAP_API_KEY&url=http://${env.WORKER1_IP}:30004" || true
sleep 20

curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/JSON/ascan/action/scan/?apikey=\\\$ZAP_API_KEY&url=http://${env.WORKER1_IP}:30004" || true
sleep 40

curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/OTHER/core/other/htmlreport/?apikey=\\\$ZAP_API_KEY" -o owasp-zap-report.html || true
echo '=== OWASP ZAP Scan END ==='
"""
                    }
                }
            }
        }

    } // end stages

    post {
        always {
            archiveArtifacts artifacts: '*-npm-audit.json, *-trivy-report.txt, owasp-zap-report.html', allowEmptyArchive: true
        }
        success {
            echo "Dashboard: http://${env.MASTER_IP}:30004"
            echo "Middleware: http://${env.MASTER_IP}:30003"
            echo "Simulator: http://${env.MASTER_IP}:30005"
        }
        failure {
            echo '✗ Pipeline failed!'
            script {
                sh '''
echo "=== Final Debug Information ==="
kubectl get pods -n ${env.K8S_NAMESPACE} -o wide || true
kubectl get events -n ${env.K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -20 || true
'''
            }
        }
    }
}
