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
        checkout scm
        withDockerRegistry(credentialsId: 'docker-hub-creds', url: 'https://index.docker.io/v1/') {
          script {
            def apps = ['cbs-simulator', 'middleware', 'dashboard']
            def imageTag = env.BUILD_NUMBER ? "${env.BUILD_NUMBER}" : 'latest'

            apps.eachWithIndex { app, idx ->
              echo "Building ${app} with tag ${imageTag}..."

              if (app == 'dashboard') {
                sh """
docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} \
  --build-arg REACT_APP_API_URL=http://middleware:3000 ./${app}
"""
              } else {
                sh "docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} ./${app}"
              }

              sh "docker push ${env.DOCKER_REGISTRY}/${app}:${imageTag}"
            }
          }
        }
      }
    }

    // ===== Trivy HTML stage (remplacé comme demandé) =====
    stage('Image Security Scan (Trivy)') {
  steps {
    script {
      def FAIL_ON_CRITICAL = (env.FAIL_ON_CRITICAL ?: 'false').toLowerCase()
      def apps = ['cbs-simulator', 'middleware', 'dashboard']
      def tag = env.BUILD_NUMBER ?: 'latest'

      apps.each { app ->
        echo "🔍 Trivy: scanning ${app} (tag=${tag})..."
        def image = "${env.DOCKER_REGISTRY}/${app}:${tag}"
        def jsonFile = "${app}-trivy.json"
        def txtFile  = "${app}-trivy.txt"
        def htmlFile = "${app}-trivy.html"

        // Run trivy (image if present, otherwise filesystem)
        sh """
set -e
if docker image inspect "${image}" >/dev/null 2>&1; then
  echo "-> Scanning image: ${image}"
  trivy image --no-progress --format json --output ${jsonFile} --severity HIGH,CRITICAL "${image}" || true
  trivy image --no-progress --format table --output ${txtFile} --severity HIGH,CRITICAL "${image}" || true
else
  echo "-> Image not found locally, scanning workspace path ./${app}"
  trivy fs --no-progress --format json --output ${jsonFile} --severity HIGH,CRITICAL ./${app} || true
  trivy fs --no-progress --format table --output ${txtFile} --severity HIGH,CRITICAL ./${app} || true
fi
"""

        // Optional: generate a simple HTML report from JSON (if jq present)
        sh """
if command -v jq >/dev/null 2>&1 && [ -f ${jsonFile} ]; then
  echo '<html><body><h2>Trivy JSON report for ${app}</h2><pre>' > ${htmlFile}
  jq . ${jsonFile} >> ${htmlFile} || true
  echo '</pre></body></html>' >> ${htmlFile} || true
fi
"""

        // Count CRITICAL vulnerabilities (python3 preferred, fallback to grep)
        def criticalCount = 0
        try {
          criticalCount = sh(returnStdout: true, script: """#!/bin/bash
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import json,sys
try:
  j = json.load(open('${jsonFile}'))
except Exception:
  print(0)
  sys.exit(0)
c = 0
for r in j.get('Results', []):
  for v in (r.get('Vulnerabilities') or []):
    if v.get('Severity','').upper() == 'CRITICAL':
      c += 1
print(c)
PY
else
  grep -o "CRITICAL" ${jsonFile} 2>/dev/null | wc -l || true
fi
""").trim()
          criticalCount = (criticalCount == '') ? 0 : (criticalCount as Integer)
        } catch (err) {
          echo "Warning: unable to compute CRITICAL count (${err}); defaulting to 0"
          criticalCount = 0
        }

        echo "-> ${app} : CRITICAL vuln count = ${criticalCount}"

        // Archive artifacts so you can view them in Jenkins UI
        archiveArtifacts artifacts: "${jsonFile}, ${txtFile}, ${htmlFile}", allowEmptyArchive: true, fingerprint: true

        // Optionally fail the build if criticals found and FAIL_ON_CRITICAL=true
        if (FAIL_ON_CRITICAL == 'true' && criticalCount > 0) {
          error("Build failed: ${criticalCount} CRITICAL vulnerabilities found in ${app}")
        }
      } // apps.each
    } // script
  } // steps
} // stage


    stage('Dynamic Security Testing (OWASP ZAP)') {
      steps {
        script {
          try {
            withCredentials([string(credentialsId: 'owasp-zap-api-key', variable: 'ZAP_API_KEY')]) {
              sh '''
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

    //---------------------------------------
    // 🚫 Stage de déploiement (commenté)
    //---------------------------------------

    // stage('Deployment to Test Env') {
    //   steps {
    //     script {
    //       echo "Deployment disabled"
    //     }
    //   }
    // }

    //---------------------------------------
    // 🚫 Stage de vérification du déploiement (commenté)
    //---------------------------------------

    // stage('Verify Deployment Health') {
    //   steps {
    //     script {
    //       echo "Health check disabled"
    //     }
    //   }
    // }

  } // END stages

  post {
    always {
      archiveArtifacts artifacts: '*-npm-audit.json, *-trivy-report.txt, *-trivy-report.html, owasp-zap-report.html', allowEmptyArchive: true, fingerprint: true
      sh "kubectl get all -n ${env.K8S_NAMESPACE} || true"
    }
    success {
      echo '✓ Pipeline completed successfully!'
    }
    failure {
      echo '❌ Pipeline failed'
    }
    unstable {
      echo '⚠ Pipeline unstable'
    }
  }
}
