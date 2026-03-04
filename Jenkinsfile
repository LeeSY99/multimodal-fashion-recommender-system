pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    PYTHON = 'python3'
    IMAGE_NAME = 'ghcr.io/leesy99/multimodal-fashion-recommender-system'
    IMAGE_TAG = "jenkins-${BUILD_NUMBER}"
    IMAGE_LATEST = "latest"
    KUBECTL_IMAGE = "bitnami/kubectl:latest"
  }

  parameters {
    booleanParam(name: 'DEPLOY_TO_K8S', defaultValue: false, description: 'Deploy to Kubernetes after CI')
    string(name: 'K8S_NAMESPACE', defaultValue: 'mfs', description: 'Kubernetes namespace for deployment')
    choice(name: 'K8S_OVERLAY', choices: ['k8s/overlays/shared-storage', 'k8s/overlays/local'], description: 'Kustomize overlay to deploy')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Run Tests with Coverage') {
      steps {
        sh '''
          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "${WORKSPACE}" \
            python:3.11-slim bash -lc '
          python -m pip install -U pip
          python -m pip install -r requirements.txt -r requirements-dev.txt
          python -m pip install pytest-cov coverage nltk
          python - <<'"'"'PY'"'"'
import nltk
nltk.download("stopwords", quiet=True)
PY
          PYTHON_BIN=python bash scripts/ci/run_pytest_coverage.sh
          '
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'pytest-report.xml'
          archiveArtifacts allowEmptyArchive: true, artifacts: 'coverage.xml'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_LATEST}
        '''
      }
    }

    stage('Push Docker Image') {
      when {
        expression { return params.DEPLOY_TO_K8S }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
          sh '''
            echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${IMAGE_NAME}:${IMAGE_LATEST}
            docker logout ghcr.io || true
          '''
        }
      }
    }

    stage('Validate K8s Access') {
      when {
        expression { return params.DEPLOY_TO_K8S }
      }
      steps {
        sh '''
          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl get ns ${K8S_NAMESPACE}
        '''
      }
    }

    stage('Validate K8s Manifests') {
      steps {
        sh '''
          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl kustomize ${K8S_OVERLAY} > /tmp/mfs-rendered.yaml
          test -s /tmp/mfs-rendered.yaml
          docker run --rm \
            -v /tmp:/tmp \
            -v jenkins_home:/var/jenkins_home \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl apply --dry-run=client -f /tmp/mfs-rendered.yaml --validate=false
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        expression { return params.DEPLOY_TO_K8S }
      }
      steps {
        sh '''
          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl apply -k ${K8S_OVERLAY}

          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl set image deployment/multimodal-fashion-recommender app=${IMAGE_NAME}:${IMAGE_TAG} -n ${K8S_NAMESPACE}

          if docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl get job mfs-sync-assets -n ${K8S_NAMESPACE} >/dev/null 2>&1; then
            docker run --rm \
              -v jenkins_home:/var/jenkins_home \
              -e KUBECONFIG=/var/jenkins_home/.kube/config \
              ${KUBECTL_IMAGE} kubectl wait --for=condition=complete job/mfs-sync-assets -n ${K8S_NAMESPACE} --timeout=900s
          fi

          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl rollout status deployment/multimodal-fashion-recommender -n ${K8S_NAMESPACE} --timeout=300s

          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -e KUBECONFIG=/var/jenkins_home/.kube/config \
            ${KUBECTL_IMAGE} kubectl get pods,svc,ingress,pvc -n ${K8S_NAMESPACE}
        '''
      }
    }
  }

  post {
    always {
      echo "Build finished: ${currentBuild.currentResult}"
    }
  }
}
