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
        WORKER1_IP = '192.168.90.129'
        WORKER2_IP = '192.168.90.137'
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
                git branch: 'main', credentialsId: 'jenkins-github', url: 'https://github.com/ahmedjallabi/CBS-Core-Banking-System-Intechgeeks.git'
            }
        }

        stage('Code Quality Analysis (SonarQube)') {
    steps {
        script {
            // Assurez-vous que le token SonarQube est défini dans Jenkins Credentials avec l'ID 'sonarqube'
            withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
                sh """
                    #!/bin/bash
                    echo "🔗 SonarQube URL: http://192.168.90.136:9000"

                    # Utiliser le container officiel du scanner
                    docker run --rm \
                        -v \$(pwd):/usr/src \
                        -e SONAR_HOST_URL=http://192.168.90.136:9000 \
                        -e SONAR_LOGIN=$SONAR_TOKEN \
                        sonarsource/sonar-scanner-cli \
                        -Dsonar.projectKey=CBS-stimul \
                        -Dsonar.sources=/usr/src \
                        -Dsonar.login=$SONAR_TOKEN \
                        -Dsonar.host.url=http://192.168.90.136:9000
                """
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
                                        --build-arg REACT_APP_API_URL=http://middleware-service:3000 \
                                        --build-arg REACT_APP_MIDDLEWARE_URL=http://middleware-service:3000 \
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
                            def port = (app == 'dashboard') ? '80' : ((app == 'middleware') ? '3000' : '4000')
                            sh "docker run --rm -d --name test-${app} -p 8080:${port} ${DOCKER_REGISTRY}/${app}:latest || true"
                            sh "sleep 5"
                            sh "curl -f http://localhost:8080 || echo '${app} health check failed'"
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
                        sh "kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"

                        echo "=== Deleting Existing Deployments and Services ==="
                        sh "kubectl delete deployment cbs-simulator middleware dashboard -n ${K8S_NAMESPACE} --ignore-not-found=true"
                        sh "kubectl delete service cbs-simulator-service cbs-simulator-nodeport middleware-service middleware-nodeport dashboard-service dashboard-nodeport -n ${K8S_NAMESPACE} --ignore-not-found=true"

                        echo "=== Waiting for Pod Termination ==="
                        sh "sleep 15"

                        echo "=== Applying New Deployments (Optimized Configuration) ==="
                        sh "kubectl apply -f kubernetes/cbs-system-optimized.yaml"

                        echo "=== Waiting for Deployments to be Ready ==="
                        def apps = ['cbs-simulator', 'middleware', 'dashboard']
                        apps.each { app ->
                            echo "Checking rollout status for: ${app}"
                            timeout(time: 6, unit: 'MINUTES') {
                                sh "kubectl rollout status deployment/${app} -n ${K8S_NAMESPACE} --timeout=300s"
                            }
                            echo "✓ ${app} deployment successful"
                        }

                        echo "=== Deployment Summary ==="
                        sh """
                            echo "Services:"
                            kubectl get services -n ${K8S_NAMESPACE}
                            echo ""
                            echo "Pods:"
                            kubectl get pods -n ${K8S_NAMESPACE} -o wide
                            echo ""
                            echo "Images in use:"
                            kubectl get deployments -n ${K8S_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{\": \"}{.spec.template.spec.containers[0].image}{\"\\n\"}{end}'
                        """
                    } catch (Exception e) {
                        echo "=== DEPLOYMENT FAILED - Gathering Debug Information ==="
                        sh """
                            echo "=== All Resources in Namespace ==="
                            kubectl get all -n ${K8S_NAMESPACE} || true
                            echo ""
                            echo "=== Deployment Details ==="
                            kubectl describe deployments -n ${K8S_NAMESPACE} || true
                            echo ""
                            echo "=== Pod Details ==="
                            kubectl describe pods -n ${K8S_NAMESPACE} || true
                            echo ""
                            echo "=== Recent Events ==="
                            kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' --field-selector type!=Normal || true
                            echo ""
                            echo "=== Pod Logs ==="
                            for pod in \$(kubectl get pods -n ${K8S_NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
                                echo "--- Logs for \$pod ---"
                                kubectl logs \$pod -n ${K8S_NAMESPACE} --tail=100 --all-containers=true || true
                                echo ""
                            done
                            echo ""
                            echo "=== Node Status ==="
                            kubectl top nodes || true
                            kubectl describe nodes || true
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
                        RUNNING_PODS=\$(kubectl get pods -n ${K8S_NAMESPACE} --field-selector=status.phase=Running --no-headers | wc -l)
                        TOTAL_PODS=\$(kubectl get pods -n ${K8S_NAMESPACE} --no-headers | wc -l)
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
                        curl -f -s -o /dev/null -w "CBS Simulator (port 30005): HTTP %{http_code}\\n" http://${MASTER_IP}:30005 || echo "CBS Simulator: Not accessible"
                        curl -f -s -o /dev/null -w "CBS Simulator Health: HTTP %{http_code}\\n" http://${MASTER_IP}:30005/health || echo "CBS Simulator /health: Not accessible"
                    """
                }
            }
        }

        stage('Test Pod Communication') {
            steps {
                script {
                    echo "=== Testing Pod-to-Pod Communication ==="
                    sh """
                        echo "Creating test pod for communication testing..."
                        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: communication-test-pod
  namespace: ${K8S_NAMESPACE}
spec:
  containers:
  - name: test-container
    image: curlimages/curl:latest
    command: ['sleep', '300']
  restartPolicy: Never
EOF
                        
                        echo "Waiting for test pod to be ready..."
                        kubectl wait --for=condition=Ready pod/communication-test-pod -n ${K8S_NAMESPACE} --timeout=60s
                        
                        echo "Testing internal communication..."
                        echo "Testing CBS Simulator service..."
                        kubectl exec -n ${K8S_NAMESPACE} communication-test-pod -- curl -s -w "CBS Simulator: HTTP %{http_code}\\n" http://cbs-simulator-service:4000/health || echo "CBS Simulator: Communication failed"
                        
                        echo "Testing Middleware service..."
                        kubectl exec -n ${K8S_NAMESPACE} communication-test-pod -- curl -s -w "Middleware: HTTP %{http_code}\\n" http://middleware-service:3000/health || echo "Middleware: Communication failed"
                        
                        echo "Testing Dashboard service..."
                        kubectl exec -n ${K8S_NAMESPACE} communication-test-pod -- curl -s -w "Dashboard: HTTP %{http_code}\\n" http://dashboard-service:80/ || echo "Dashboard: Communication failed"
                        
                        echo "Testing Middleware -> CBS Simulator communication..."
                        kubectl exec -n ${K8S_NAMESPACE} communication-test-pod -- curl -s -w "Middleware->CBS: HTTP %{http_code}\\n" http://middleware-service:3000/customers/C001 || echo "Middleware->CBS: Communication failed"
                        
                        echo "Cleaning up test pod..."
                        kubectl delete pod communication-test-pod -n ${K8S_NAMESPACE} || true
                        
                        echo "✓ Pod communication tests completed"
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
                            sh "curl 'http://${ZAP_HOST}:${ZAP_PORT}/JSON/spider/action/scan/?apikey=${ZAP_API_KEY}&url=http://${MASTER_IP}:30004' || true"
                            sh "sleep 30"
                            echo "Initiating active scan..."
                            sh "curl 'http://${ZAP_HOST}:${ZAP_PORT}/JSON/ascan/action/scan/?apikey=${ZAP_API_KEY}&url=http://${MASTER_IP}:30004' || true"
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
                sh "kubectl get all -n ${K8S_NAMESPACE} || true"
            }
        }
        success {
            echo '✓ Pipeline completed successfully!'
            echo '=== Access URLs ==='
            echo "Dashboard: http://${MASTER_IP}:30004"
            echo "Middleware API: http://${MASTER_IP}:30003"
            echo "CBS Simulator: http://${MASTER_IP}:30005"
            echo ""
            echo "=== Health Check URLs ==="
            echo "Dashboard Health: http://${MASTER_IP}:30004/"
            echo "Middleware Health: http://${MASTER_IP}:30003/health"
            echo "CBS Simulator Health: http://${MASTER_IP}:30005/health"
            echo ""
            echo "=== API Documentation ==="
            echo "Middleware API Docs: http://${MASTER_IP}:30003/api-docs"
        }
        failure {
            echo '✗ Pipeline failed!'
        }
        unstable {
            echo '⚠ Pipeline completed with warnings'
        }
    }
}
