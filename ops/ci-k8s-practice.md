# CI/K8s Practice Guide

이 문서는 IT 직무 포트폴리오용으로 아래 3가지를 빠르게 실습하는 가이드입니다.

1. Jenkins CI 파이프라인 구축
2. pytest + coverage CI 적용
3. Docker Compose -> Kubernetes 배포 실습

## 1) Jenkins CI

레포 루트의 `Jenkinsfile`을 사용합니다.

파이프라인 단계:
- Checkout
- 의존성 설치
- 테스트 + 커버리지 리포트 생성
- Docker 이미지 빌드
- Kubernetes 매니페스트 검증
- (옵션) Kubernetes 배포

Jenkins에서 필요한 도구:
- Python 3.11+
- Docker
- kubectl

## 2) pytest + coverage (로컬/CI 공통)

실행 스크립트:
```bash
bash scripts/ci/run_pytest_coverage.sh
```

산출물:
- `coverage.xml`
- `pytest-report.xml`

기준:
- `--cov-fail-under=60`

## 3) Kubernetes 배포 실습

### A. 매니페스트 렌더링 확인
```bash
kubectl kustomize k8s/base
```

### B. 로컬 오버레이 적용 (minikube/kind)
```bash
kubectl apply -k k8s/overlays/local
kubectl get pods -n mfs
kubectl get svc -n mfs
```

### C. 롤아웃 확인
```bash
kubectl rollout status deployment/multimodal-fashion-recommender -n mfs
```

## 면접/자소서 포인트
- CI에서 테스트와 커버리지 기준을 게이트로 설정해 품질 기준 자동화
- Docker 빌드와 Kubernetes 매니페스트 검증을 CI 단계에 통합
- Compose 기반 개발 환경에서 Kubernetes 배포 형태까지 확장한 경험 확보
