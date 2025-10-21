pipeline {
    agent any

    environment {
        // Docker
        DOCKER_REGISTRY = 'ahm2022'

        // Kubernetes
        K8S_NAMESPACE = 'cbs-system'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'

        // OWASP ZAP
        ZAP_HOST = '192.168.90.129'
        ZAP_PORT = '8090'

        // Cluster IPs
        MASTER_IP = '192.168.90.129'
        WORKER1_IP = '192.168.90.130'
        WORKER2_IP = '192.168.90.131'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 2, unit: 'HOURS')
        timestamps()
    }

    // Définition de fonctions utiles
    // Cette fonction encapsule kubectl avec l'option --insecure-skip-tls-verify
    // Usage: kubectl_safe("get pods -n ${K8S_NAMESPACE}")
    def kubectl_safe(cmd) {
        sh "kubectl --insecure-skip-tls-verify ${cmd}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'jenkins-github', url: 'https://github.com/ahmedjallabi/CBS-Core-Banking-System-Intechgeeks.git'
            }
        }

        stage('Code Quality Analysis (SonarQube)') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        /usr/local/bin/sonar-scanner \
                          -Dsonar.projectKey=CBS-stimul \
                          -Dsonar.sources=. \
                          -Dsonar.login=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Dependency Audit (npm audit)') {
            steps {
                script {
                    def apps = ['cbs-simulator', 'middleware', 'dashboard']
                    apps.each { app ->
                        dir(app) {
                            echo "🔍 Running npm audit for ${app}..."
                            sh 'npm install --no-audit --no-fund'
                            sh "npm audit --json > ../${app}-npm-audit.json || true"
                            sh "npm audit --audit-level=high || true"
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
                            echo "Building ${app}..."
                            if (app == 'dashboard') {
                                sh """
                                    docker build --no-cache \
                                        -t ${DOCKER_REGISTRY}/${app}:latest \
                                        --build-arg REACT_APP_API_URL=http://${MASTER_IP}:30003 \
                                        ./${app}
                                """
                            } else {
                                sh """
                                    docker build --no-cache \
                                        -t ${DOCKER_REGISTRY}/${app}:latest \
                                        ./${app}
                                """
                            }
                            echo "Testing ${app} image locally..."
                            sh "docker run --rm -d --name test-${app} -p 8080:80 ${DOCKER_REGISTRY}/${app}:latest || true"
                            sh "sleep 5"
                            sh "curl -f http://localhost:8080 || echo 'Health check failed'"
                            sh "docker stop test-${app} || true"
                            sh "docker rm test-${app} || true"
                            echo "Pushing ${app}..."
                            sh "docker push ${DOCKER_REGISTRY}/${app}:latest"
                            echo "✓ ${app} built and pushed successfully"
                        }
                    }
                }
            }
        }

        stage('Image Security Scan (Trivy)') {
            steps {
                script {
                    def apps = ['cbs-simulator', 'middleware', 'dashboard']
                    apps.each { app ->
                        echo "🔍 Scanning ${app} for vulnerabilities..."
                        sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_REGISTRY}/${app}:latest > ${app}-trivy-report.txt || true"
                    }
                }
            }
        }

        stage('Deployment to Test Env') {
            steps {
                script {
                    try {
                        echo "=== Creating/Verifying Namespace ==="
                        kubectl_safe("create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -")

                        echo "=== Deleting Existing Deployments ==="
                        kubectl_safe("delete deployment cbs-simulator middleware dashboard -n ${K8S_NAMESPACE} --ignore-not-found=true")

                        echo "=== Waiting for Pod Termination ==="
                        sh "sleep 15"

                        echo "=== Applying New Deployments ==="
                        kubectl_safe("apply -f kubernetes/deploy-all.yaml")

                        echo "=== Waiting for Deployments to be Ready ==="
                        def apps = ['cbs-simulator', 'middleware', 'dashboard']
                        apps.each { app ->
                            echo "Checking rollout status for: ${app}"
                            timeout(time: 6, unit: 'MINUTES') {
                                kubectl_safe("rollout status deployment/${app} -n ${K8S_NAMESPACE} --timeout=300s")
                            }
                            echo "✓ ${app} deployment successful"
                        }

                        echo "=== Deployment Summary ==="
                        sh """
                            echo "Services:"
                            ${kubectl_safe("get services -n ${K8S_NAMESPACE}")}
                            echo ""
                            echo "Pods:"
                            ${kubectl_safe("get pods -n ${K8S_NAMESPACE} -o wide")}
                            echo ""
                            echo "Images in use:"
                            ${kubectl_safe("get deployments -n ${K8S_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{\": \"}{.spec.template.spec.containers[0].image}{\"\\n\"}{end}'")}
                        """
                    } catch (Exception e) {
                        echo "=== DEPLOYMENT FAILED - Gathering Debug Information ==="
                        sh """
                            echo "=== All Resources in Namespace ==="
                            ${kubectl_safe("get all -n ${K8S_NAMESPACE}")}
                            echo ""
                            echo "=== Deployment Details ==="
                            ${kubectl_safe("describe deployments -n ${K8S_NAMESPACE}")}
                            echo ""
                            echo "=== Pod Details ==="
                            ${kubectl_safe("describe pods -n ${K8S_NAMESPACE}")}
                            echo ""
                            echo "=== Recent Events ==="
                            ${kubectl_safe("get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' --field-selector type!=Normal")}
                        """
                        error("Deployment failed: ${e.message}")
                    }
                }
            }
        }

        stage('Verify Deployment Health') {
            steps {
                script {
                    echo "=== Verifying Application Health ==="
                    sh """
                        sleep 15
                        RUNNING_PODS=\$(kubectl --insecure-skip-tls-verify get pods -n ${K8S_NAMESPACE} --field-selector=status.phase=Running --no-headers | wc -l)
                        TOTAL_PODS=\$(kubectl --insecure-skip-tls-verify get pods -n ${K8S_NAMESPACE} --no-headers | wc -l)
                        echo "Running Pods: \$RUNNING_PODS / \$TOTAL_PODS"
                        if [ "\$RUNNING_PODS" -eq 0 ]; then
                            echo "ERROR: No pods are running!"
                            exit 1
                        fi
                        echo ""
                        echo "Testing service endpoints..."
                        curl -f -s -o /dev/null -w "Dashboard (port 30004): HTTP %{http_code}\\n" http://${MASTER_IP}:30004 || echo "Dashboard: Not accessible"
                        curl -f -s -o /dev/null -w "Middleware (port 30003): HTTP %{http_code}\\n" http://${MASTER_IP}:30003 || echo "Middleware: Not accessible"
                        curl -f -s -o /dev/null -w "Middleware Health: HTTP %{http_code}\\n" http://${MASTER_IP}:30003/health || echo "Middleware /health: Not accessible"
                        curl -f -s -o /dev/null -w "Simulator (port 30005): HTTP %{http_code}\\n" http://${MASTER_IP}:30005 || echo "Simulator: Not accessible"
                    """
                }
            }
        }

        stage('Dynamic Security Testing (OWASP ZAP)') {
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'owasp-zap-api-key', variable: 'ZAP_API_KEY')]) {
                            echo "=== Starting OWASP ZAP Security Scan ==="
                            sh "sleep 10"
                            echo "Initiating spider scan..."
                            sh "curl 'http://${ZAP_HOST}:${ZAP_PORT}/JSON/spider/action/scan/?apikey=${ZAP_API_KEY}&url=http://${WORKER1_IP}:30004' || true"
                            sh "sleep 30"
                            echo "Initiating active scan..."
                            sh "curl 'http://${ZAP_HOST}:${ZAP_PORT}/JSON/ascan/action/scan/?apikey=${ZAP_API_KEY}&url=http://${WORKER1_IP}:30004' || true"
                            sh "sleep 60"
                            echo "Generating report..."
                            sh "curl 'http://${ZAP_HOST}:${ZAP_PORT}/OTHER/core/other/htmlreport/?apikey=${ZAP_API_KEY}' -o owasp-zap-report.html || true"
                        }
                    } catch (Exception e) {
                        echo "OWASP ZAP scan failed: ${e.message}"
                        echo "Continuing pipeline execution..."
                    }
                }
            }
        }
    }

    post {
        always {
            echo '=== Pipeline Execution Complete ==='
            script {
                archiveArtifacts artifacts: '*-npm-audit.json, *-trivy-report.txt, owasp-zap-report.html', allowEmptyArchive: true, fingerprint: true
                kubectl_safe("get all -n ${K8S_NAMESPACE} || true")
            }
        }
        success {
            echo '✓ Pipeline completed successfully!'
            echo '=== Access URLs ==='
            echo "Dashboard: http://${MASTER_IP}:30004"
            echo "Middleware: http://${MASTER_IP}:30003"
            echo "Simulator: http://${MASTER_IP}:30005"
        }
        failure {
            echo '✗ Pipeline failed!'
            script {
                sh """
                    echo "=== Final Debug Information ==="
                    kubectl --insecure-skip-tls-verify get pods -n ${K8S_NAMESPACE} -o wide || true
                    kubectl --insecure-skip-tls-verify get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -20 || true
                """
            }
        }
        unstable {
            echo '⚠ Pipeline completed with warnings'
        }
    }
}
