# Jenkins + K3s CI/CD Quick Guide

이 문서는 EC2 단일 서버에서 Jenkins로 CI/CD를 실행할 때 필요한 최소 설정을 정리합니다.

## 1) 사전 조건

- Jenkins 설치 완료
- Jenkins 실행 사용자(`jenkins`)가 Docker/Kubernetes 명령 사용 가능
- 저장소 최신 코드 pull 완료

## 2) Jenkins 서버 권한 설정

```bash
sudo usermod -aG docker jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod 600 /var/lib/jenkins/.kube/config
sudo systemctl restart jenkins
```

검증(서버에서):

```bash
sudo -u jenkins -H kubectl get nodes
sudo -u jenkins -H docker ps
```

## 3) Jenkins Credential 추가

`Manage Jenkins -> Credentials -> (global) -> Add Credentials`

- Kind: `Username with password`
- ID: `ghcr-creds`
- Username: GitHub 계정명
- Password: GitHub PAT (`write:packages`, `read:packages`)

## 4) Pipeline Job 파라미터

- `DEPLOY_TO_K8S=true`
- `K8S_NAMESPACE=mfs`
- `K8S_OVERLAY=k8s/overlays/shared-storage`

## 5) 첫 배포 실행

Jenkins `Build with Parameters` 실행 후, 아래 스테이지 통과 확인:

1. `Run Tests with Coverage`
2. `Build Docker Image`
3. `Push Docker Image`
4. `Validate K8s Manifests`
5. `Deploy to Kubernetes`

## 6) 배포 후 확인

```bash
kubectl get pods,svc,ingress,pvc -n mfs
kubectl get job mfs-sync-assets -n mfs
kubectl rollout status deployment/multimodal-fashion-recommender -n mfs
kubectl describe pod -n mfs -l app=multimodal-fashion-recommender
```

## 7) 자주 나는 오류

1. `docker: permission denied`
- 원인: `jenkins`가 `docker` 그룹에 없음
- 조치: `usermod -aG docker jenkins` 후 Jenkins 재시작

2. `Unable to connect to the server`
- 원인: Jenkins 사용자 kubeconfig 미설정
- 조치: `/var/lib/jenkins/.kube/config` 권한/경로 재확인

3. `ImagePullBackOff` (GHCR private 이미지)
- 원인: 클러스터 이미지 풀 인증 없음
- 조치: `imagePullSecret` 생성 후 Deployment에 연결

```bash
kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<github-pat> \
  --docker-email=<email> \
  -n mfs
```
