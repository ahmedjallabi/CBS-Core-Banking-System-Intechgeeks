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
            // Utilise env.WORKSPACE pour monter le workspace dans le conteneur
            sh """#!/bin/bash
echo "🔗 SonarQube URL: http://192.168.90.136:9000"

docker run --rm \
  -v "${env.WORKSPACE}":/usr/src \
  -e SONAR_HOST_URL=http://192.168.90.136:9000 \
  -e SONAR_LOGIN="${env.SONAR_TOKEN}" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=CBS-stimul \
  -Dsonar.sources=/usr/src \
  -Dsonar.login="${env.SONAR_TOKEN}" \
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
              sh 'npm install --no-audit --no-fund'
              sh "npm audit --json > \"${env.WORKSPACE}/${app}-npm-audit.json\" || true"
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
                sh """#!/bin/bash
docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} \
  --build-arg REACT_APP_API_URL=http://middleware:3000 ./${app}
"""
              } else {
                sh """#!/bin/bash
docker build --no-cache -t ${env.DOCKER_REGISTRY}/${app}:${imageTag} ./${app}
"""
              }

              sh "docker push ${env.DOCKER_REGISTRY}/${app}:${imageTag}"
            }
          }
        }
      }
    }

    // ===== Trivy HTML stage corrigé : on définit explicitement `image` =====
    stage('Image Security Scan (Trivy - HTML)') {
      steps {
        script {
          def apps = ['cbs-simulator', 'middleware', 'dashboard']
          def imageTag = env.BUILD_NUMBER ? "${env.BUILD_NUMBER}" : 'latest'

          apps.each { app ->
            // Définition Groovy claire de l'image (évite toute variable non-définie)
            def image = "${env.DOCKER_REGISTRY}/${app}:${imageTag}"
            echo "📄 Generating HTML vulnerability report for ${app} (image=${image})..."

            // Exécute trivy via le conteneur officiel en montant le workspace pour écrire le rapport
            // Utilise env.WORKSPACE pour éviter les confusions $(pwd)
            sh """#!/bin/bash
set -e
# Tenter de générer un rapport HTML (template fourni dans l'image trivy)
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${env.WORKSPACE}":/reports \
  aquasec/trivy:latest image \
  --format template \
  --template "@/contrib/html.tpl" \
  -o /reports/${app}-trivy-report.html \
  ${image} || true

# Fallback: si le HTML n'a pas été produit, produire un rapport texte (table)
if [ ! -f "${env.WORKSPACE}/${app}-trivy-report.html" ]; then
  echo "HTML report not found for ${app}, generating plain text report..."
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${env.WORKSPACE}":/reports \
    aquasec/trivy:latest image --format table --no-progress ${image} > "${env.WORKSPACE}/${app}-trivy-report.txt" || true
fi
"""
          }
        }
      }
    }

    stage('Dynamic Security Testing (OWASP ZAP)') {
      steps {
        script {
          try {
            // withCredentials crée temporairement l'env ZAP_API_KEY accessible via env.ZAP_API_KEY
            withCredentials([string(credentialsId: 'owasp-zap-api-key', variable: 'ZAP_API_KEY')]) {
              // utilise env.* pour interpolation Groovy sûre
              sh """#!/bin/bash
set -eux
curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/JSON/spider/action/scan/?apikey=${env.ZAP_API_KEY}&url=http://${env.WORKER1_IP}:30004" || true
sleep 30
curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/JSON/ascan/action/scan/?apikey=${env.ZAP_API_KEY}&url=http://${env.WORKER1_IP}:30004" || true
sleep 60
curl -v "http://${env.ZAP_HOST}:${env.ZAP_PORT}/OTHER/core/other/htmlreport/?apikey=${env.ZAP_API_KEY}" -o "${env.WORKSPACE}/owasp-zap-report.html" || true
"""
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
