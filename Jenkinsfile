pipeline {
  agent any

  triggers {
    githubPush()
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    PYTHON = 'python3'
    PYTEST_WORKERS = 'auto'
    IMAGE_NAME = 'ghcr.io/leesy99/multimodal-fashion-recommender-system'
    IMAGE_TAG = "jenkins-${BUILD_NUMBER}"
    IMAGE_LATEST = "latest"
    KUBECTL_IMAGE = "bitnami/kubectl:latest"
    K3S_KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"
  }

  parameters {
    booleanParam(name: 'DEPLOY_TO_K8S', defaultValue: true, description: 'Deploy to Kubernetes after CI')
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
          REQ_HASH="$(sha256sum requirements-ci.txt | awk '{print substr($1,1,12)}')"
          CI_TEST_IMAGE="mfs-ci-test:${REQ_HASH}"

          if ! docker image inspect "${CI_TEST_IMAGE}" >/dev/null 2>&1; then
            docker build \
              -f docker/ci-test.Dockerfile \
              --build-arg REQUIREMENTS_FILE=requirements-ci.txt \
              -t "${CI_TEST_IMAGE}" .
          fi

          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "${WORKSPACE}" \
            -e PYTEST_WORKERS="${PYTEST_WORKERS}" \
            "${CI_TEST_IMAGE}" bash -lc '
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
        withCredentials([usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
          sh '''
            if docker buildx version >/dev/null 2>&1; then
              docker buildx inspect jenkins-buildx >/dev/null 2>&1 || \
                docker buildx create --name jenkins-buildx --driver docker-container --use
              docker buildx use jenkins-buildx

              echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin
              docker buildx build \
                -f dockerfile \
                -t ${IMAGE_NAME}:${IMAGE_TAG} \
                -t ${IMAGE_NAME}:${IMAGE_LATEST} \
                --cache-from type=registry,ref=${IMAGE_NAME}:buildcache \
                --cache-to type=registry,ref=${IMAGE_NAME}:buildcache,mode=max \
                --load \
                .
              docker logout ghcr.io || true
            else
              docker build -f dockerfile -t ${IMAGE_NAME}:${IMAGE_TAG} .
              docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_LATEST}
            fi
          '''
        }
      }
    }

    stage('Push Docker Image') {
      when {
        expression {
          return (
            (env.BRANCH_NAME == 'main') ||
            (env.GIT_BRANCH?.endsWith('/main'))
          )
        }
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
        expression {
          return (
            (env.BRANCH_NAME == 'main') ||
            (env.GIT_BRANCH?.endsWith('/main'))
          )
        }
      }
      steps {
        sh '''
          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} delete job mfs-sync-assets -n ${K8S_NAMESPACE} --ignore-not-found=true

          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} cluster-info
        '''
      }
    }

    stage('Validate K8s Manifests') {
      when {
        expression {
          return (
            (env.BRANCH_NAME == 'main') ||
            (env.GIT_BRANCH?.endsWith('/main'))
          )
        }
      }
      steps {
        sh '''
          OVERLAY_PATH="${K8S_OVERLAY:-k8s/overlays/shared-storage}"
          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} kustomize "${OVERLAY_PATH}" \
          | docker run --rm -i \
            --user 0:0 \
            --network host \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} apply --dry-run=client -f - --validate=false
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        expression {
          return (
            (env.BRANCH_NAME == 'main') ||
            (env.GIT_BRANCH?.endsWith('/main'))
          )
        }
      }
      steps {
        sh '''
          OVERLAY_PATH="${K8S_OVERLAY:-k8s/overlays/shared-storage}"
          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -w "${WORKSPACE}" \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} apply -k "${OVERLAY_PATH}"

          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} set image deployment/multimodal-fashion-recommender app=${IMAGE_NAME}:${IMAGE_TAG} -n ${K8S_NAMESPACE}

          if docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} get job mfs-sync-assets -n ${K8S_NAMESPACE} >/dev/null 2>&1; then
            docker run --rm \
              --user 0:0 \
              --network host \
              -v jenkins_home:/var/jenkins_home \
              -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
              -e KUBECONFIG=/kubeconfig \
              ${KUBECTL_IMAGE} wait --for=condition=complete job/mfs-sync-assets -n ${K8S_NAMESPACE} --timeout=900s || {
                docker run --rm \
                  --user 0:0 \
                  --network host \
                  -v jenkins_home:/var/jenkins_home \
                  -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
                  -e KUBECONFIG=/kubeconfig \
                  ${KUBECTL_IMAGE} get pods -n ${K8S_NAMESPACE} -l job-name=mfs-sync-assets -o wide || true
                docker run --rm \
                  --user 0:0 \
                  --network host \
                  -v jenkins_home:/var/jenkins_home \
                  -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
                  -e KUBECONFIG=/kubeconfig \
                  ${KUBECTL_IMAGE} logs -n ${K8S_NAMESPACE} job/mfs-sync-assets --tail=200 || true
                exit 1
              }
          fi

          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} rollout status deployment/multimodal-fashion-recommender -n ${K8S_NAMESPACE} --timeout=1200s

          docker run --rm \
            --user 0:0 \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v ${K3S_KUBECONFIG}:/kubeconfig:ro \
            -e KUBECONFIG=/kubeconfig \
            ${KUBECTL_IMAGE} get pods,svc,ingress,pvc -n ${K8S_NAMESPACE}
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
