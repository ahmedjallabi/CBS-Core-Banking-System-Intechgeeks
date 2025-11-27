pipeline {
  agent any

  environment {
    DOCKER_REGISTRY = 'ahm2022'
    K8S_NAMESPACE    = 'cbs-system'
    KUBECONFIG       = '/var/lib/jenkins/.kube/config'
    ZAP_HOST         = '192.168.90.136'
    ZAP_PORT         = '8090'
    MASTER_IP        = '192.168.90.136'
    WORKER1_IP       = '192.168.90.128'
    WORKER2_IP       = '192.168.90.129'
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
        checkout scm
      }
    }

    stage('Code Quality Analysis (SonarQube)') {
      steps {
        script {
          withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_TOKEN')]) {
            sh '''#!/bin/bash
echo "🔗 SonarQube URL: http://192.168.90.136:9000"

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
        // ensure we have the latest Jenkinsfile/workspace when restarting from stage
        checkout scm

        withDockerRegistry(credentialsId: 'docker-hub-creds', url: 'https://index.docker.io/v1/') {
          script {
            def apps = ['cbs-simulator', 'middleware', 'dashboard']
            def imageTag = env.BUILD_NUMBER ? "${env.BUILD_NUMBER}" : 'latest'

            apps.eachWithIndex { app, idx ->
              if (!app) {
                error("ERROR: app variable is empty — aborting to avoid invalid image tag")
              }

              echo "Building ${app} with tag ${imageTag}..."

              if (app == 'dashboard') {
                sh """
                  docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} --build-arg REACT_APP_API_URL=http://middleware:3000 ./${app}
                """
              } else {
                sh "docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} ./${app}"
              }

              // simple container smoke test (use different host port per app)
              def hostPort = 8080 + idx
              // For non-dashboard apps the internal port might not be 80; adapt if needed.
              sh "docker run --rm -d --name test-${app} -p ${hostPort}:80 ${env.DOCKER_REGISTRY}/${app}:${imageTag} || true"
              sh 'sleep 5'
              sh "curl -f http://localhost:${hostPort} || echo 'Health check failed for ${app} on port ${hostPort}'"
              sh "docker stop test-${app} || true"
              sh "docker rm test-${app} || true"

              sh "docker push ${env.DOCKER_REGISTRY}/${app}:${imageTag}"
              echo "✓ ${app} built and pushed: ${env.DOCKER_REGISTRY}/${app}:${imageTag}"
            }
          }
        }
      }
    }

    stage('Image Security Scan (Trivy)') {
      steps {
        script {
          def apps = ['cbs-simulator', 'middleware', 'dashboard']
          def imageTag = env.BUILD_NUMBER ? "${env.BUILD_NUMBER}" : 'latest'
          apps.each { app ->
            echo "🔍 Scanning ${app} for vulnerabilities..."
            sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${env.DOCKER_REGISTRY}/${app}:${imageTag} > ${app}-trivy-report.txt || true"
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
                        
                        echo "=== Deleting Existing Deployments ==="
                        sh "kubectl delete deployment cbs-simulator middleware dashboard -n ${K8S_NAMESPACE} --ignore-not-found=true"
                        
                        echo "=== Waiting for Pod Termination ==="
                        sh "sleep 15"
                        
                        echo "=== Applying New Deployments ==="
                        sh "kubectl apply -f kubernetes/deploy-all.yaml"
                        
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
                            kubectl get deployments -n ${K8S_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.template.spec.containers[0].image}{"\\n"}{end}'
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
          sh """#!/bin/bash
sleep 15
RUNNING_PODS=$(kubectl get pods -n ${env.K8S_NAMESPACE} --field-selector=status.phase=Running --no-headers | wc -l)
TOTAL_PODS=$(kubectl get pods -n ${env.K8S_NAMESPACE} --no-headers | wc -l)
echo "Running Pods: $RUNNING_PODS / $TOTAL_PODS"
if [ "$RUNNING_PODS" -eq 0 ]; then
  echo "ERROR: No pods are running!"
  exit 1
fi

curl -f -s -o /dev/null -w "Dashboard (port 30004): HTTP %{http_code}\n" http://${MASTER_IP}:30004 || echo "Dashboard: Not accessible"
curl -f -s -o /dev/null -w "Middleware (port 30003): HTTP %{http_code}\n" http://${MASTER_IP}:30003 || echo "Middleware: Not accessible"
curl -f -s -o /dev/null -w "Middleware Health: HTTP %{http_code}\n" http://${MASTER_IP}:30003/health || echo "Middleware /health: Not accessible"
curl -f -s -o /dev/null -w "Simulator (port 30005): HTTP %{http_code}\n" http://${MASTER_IP}:30005 || echo "Simulator: Not accessible"
"""
        }
      }
    }

    stage('Dynamic Security Testing (OWASP ZAP)') {
      steps {
        script {
          try {
            withCredentials([string(credentialsId: 'owasp-zap-api-key', variable: 'ZAP_API_KEY')]) {
              sh '''
set -eux
export ZAP_HOST=${ZAP_HOST}
export ZAP_PORT=${ZAP_PORT}
sleep 5
curl -v "http://$ZAP_HOST:$ZAP_PORT/JSON/spider/action/scan/?apikey=${ZAP_API_KEY}&url=http://${WORKER1_IP}:30004" || true
sleep 30
curl -v "http://$ZAP_HOST:$ZAP_PORT/JSON/ascan/action/scan/?apikey=${ZAP_API_KEY}&url=http://${WORKER1_IP}:30004" || true
sleep 60
curl -v "http://$ZAP_HOST:$ZAP_PORT/OTHER/core/other/htmlreport/?apikey=${ZAP_API_KEY}" -o owasp-zap-report.html || true
'''
            }
          } catch (Exception e) {
            echo "OWASP ZAP scan failed: ${e.message}"
          }
        }
      }
    }
  } // stages

  post {
    always {
      archiveArtifacts artifacts: '*-npm-audit.json, *-trivy-report.txt, owasp-zap-report.html', allowEmptyArchive: true, fingerprint: true
      sh "kubectl get all -n ${env.K8S_NAMESPACE} || true"
    }
    success {
      echo '✓ Pipeline completed successfully!'
      echo "Dashboard: http://${MASTER_IP}:30004"
      echo "Middleware: http://${MASTER_IP}:30003"
      echo "Simulator: http://${MASTER_IP}:30005"
    }
    failure {
      script {
        sh '''
kubectl get pods -n ${K8S_NAMESPACE} -o wide || true
kubectl get events -n ${K8S_NAMESPACE} --sort-by='.lastTimestamp' | tail -20 || true
'''
      }
    }
    unstable {
      echo '⚠ Pipeline completed with warnings'
    }
  }
}
