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

    // ===== Trivy: scan des images construites (après Docker Build & Push) =====
    stage('Image Security Scan (Trivy)') {
      steps {
        script {
          // Mettre FAIL_ON_CRITICAL=true dans les variables de job si tu veux que la build échoue
          def FAIL_ON_CRITICAL = (env.FAIL_ON_CRITICAL ?: 'false').toLowerCase()
          def apps = ['cbs-simulator', 'middleware', 'dashboard']
          def imageTag = env.BUILD_NUMBER ? "${env.BUILD_NUMBER}" : 'latest'

          // essayer d'assurer UTF-8 pour subprocesses
          sh 'export LC_ALL=C.UTF-8 || true'

          apps.each { app ->
            echo "🔍 Trivy: scanning ${app}..."
            def jsonFile = "${app}-trivy.json"
            def txtFile  = "${app}-trivy.txt"

            // Scan image si présente localement, sinon scan filesystem
            sh """
set -e
IMAGE="${env.DOCKER_REGISTRY}/${app}:${imageTag}"
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "-> Scanning image: $IMAGE"
  trivy image --no-progress --format json --output ${jsonFile} --severity HIGH,CRITICAL "$IMAGE" || true
  trivy image --no-progress --format table --output ${txtFile} --severity HIGH,CRITICAL "$IMAGE" || true
else
  echo "-> Image not found locally, scanning filesystem ./${app}"
  trivy fs --no-progress --format json --output ${jsonFile} --severity HIGH,CRITICAL ./${app} || true
  trivy fs --no-progress --format table --output ${txtFile} --severity HIGH,CRITICAL ./${app} || true
fi
"""

            // Calculer le nombre de vulnérabilités CRITICAL (préférence python3, fallback grep)
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
              echo "Warning: impossible de calculer exactement CRITICAL count (${err}); fallback to 0"
              criticalCount = 0
            }

            echo "-> ${app} : CRITICAL vuln count = ${criticalCount}"

            // Générer un HTML simple à partir du JSON si jq est présent (pratique pour visualiser)
            sh """
if command -v jq >/dev/null 2>&1 && [ -f ${jsonFile} ]; then
  echo '<html><body><h2>Trivy JSON report for ${app}</h2><pre>' > ${app}-trivy.html
  jq . ${jsonFile} >> ${app}-trivy.html || true
  echo '</pre></body></html>' >> ${app}-trivy.html || true
fi
"""

            // Archiver les rapports
            archiveArtifacts artifacts: "${jsonFile}, ${txtFile}, ${app}-trivy.html", allowEmptyArchive: true, fingerprint: true

            // Optionnel : échouer la build si CRITICAL>0 et variable FAIL_ON_CRITICAL=true
            if (FAIL_ON_CRITICAL == 'true' && criticalCount > 0) {
              error("Build failed: ${criticalCount} CRITICAL vulnerabilities found in ${app}")
            }
          } // apps.each
        } // script
      } // steps
    } // stage (Trivy)

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
      // Archive glob patterns mis à jour pour inclure les rapports Trivy JSON/TXT/HTML
      archiveArtifacts artifacts: '*-npm-audit.json, *-trivy.txt, *-trivy.json, *-trivy.html, owasp-zap-report.html', allowEmptyArchive: true, fingerprint: true
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
