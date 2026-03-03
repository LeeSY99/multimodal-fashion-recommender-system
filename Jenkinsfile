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
  }

  parameters {
    booleanParam(name: 'DEPLOY_TO_K8S', defaultValue: false, description: 'Deploy to Kubernetes after CI')
    string(name: 'K8S_NAMESPACE', defaultValue: 'mfs', description: 'Kubernetes namespace for deployment')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        sh '''
          ${PYTHON} -m pip install -U pip
          ${PYTHON} -m pip install -r requirements.txt -r requirements-dev.txt
          ${PYTHON} -m pip install pytest-cov coverage
          ${PYTHON} - <<'PY'
import nltk
nltk.download('stopwords', quiet=True)
PY
        '''
      }
    }

    stage('Run Tests with Coverage') {
      steps {
        sh '''
          PYTHON_BIN=${PYTHON} bash scripts/ci/run_pytest_coverage.sh
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
        '''
      }
    }

    stage('Validate K8s Manifests') {
      steps {
        sh '''
          kubectl kustomize k8s/base > /tmp/mfs-rendered.yaml
          test -s /tmp/mfs-rendered.yaml
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        expression { return params.DEPLOY_TO_K8S }
      }
      steps {
        sh '''
          kubectl apply -k k8s/base -n ${K8S_NAMESPACE}
          kubectl rollout status deployment/multimodal-fashion-recommender -n ${K8S_NAMESPACE} --timeout=180s
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
