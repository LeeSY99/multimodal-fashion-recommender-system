# Single-Node K3s Deployment Guide

이 디렉터리는 단일 EC2 서버(k3s)에서 이 서비스를 Kubernetes로 배포하기 위한 매니페스트입니다.
아티팩트(데이터/모델)는 `initContainer`가 GitHub Release에서 받아와 Pod 볼륨에 채웁니다.

## 1) 파일 역할

- `base/namespace.yaml`
  - `mfs` 네임스페이스 생성
- `base/deployment.yaml`
  - 애플리케이션 Pod/Replica 정의
  - `initContainer(fetch-assets)`가 Release 아티팩트를 다운로드
  - 앱 컨테이너는 initContainer가 채운 볼륨(`/app/data`, `/app/models`)을 읽기 전용으로 사용
- `base/service.yaml`
  - 클러스터 내부 포트 `80 -> 3000` 연결
- `base/ingress.yaml`
  - 외부 HTTP 요청을 Service로 라우팅 (k3s 기본 traefik)
- `base/kustomization.yaml`
  - 위 리소스를 하나로 묶고 `config/als_model.yaml`을 ConfigMap으로 주입
  - `scripts/fetch_assets.sh`를 ConfigMap으로 주입
- `overlays/local/*`
  - 단일 서버 실습용 override (이미지 태그/Ingress host)

## 2) 배포 전 준비 (EC2)

1. k3s 설치
2. Ingress host 수정

```bash
vi k8s/overlays/local/patch-ingress.yaml
```

`<EC2_PUBLIC_IP>.nip.io`를 실제 공인 IP로 변경:

예: `3.35.12.100.nip.io`

3. (옵션) 아티팩트 버전 변경

`k8s/base/deployment.yaml`의 initContainer env 값 수정:
- `DATA_ASSETS_VER` (예: `d0.1.0`)
- `MODEL_ASSETS_VER` (예: `m0.1.0`)

## 3) 배포

```bash
kubectl apply -k k8s/overlays/local
kubectl get all -n mfs
kubectl get ingress -n mfs
```

## 4) 점검

```bash
kubectl rollout status deployment/multimodal-fashion-recommender -n mfs
kubectl logs -n mfs deploy/multimodal-fashion-recommender --tail=100
```

브라우저 접속:

`http://<EC2_PUBLIC_IP>.nip.io/ui/`

## 5) Replica를 늘리면 어떻게 되나

- 현재 구조는 Pod마다 initContainer가 아티팩트를 다시 다운로드합니다.
- 장점: 노드 로컬 파일 의존이 없어 재현성이 높음.
- 단점: Replica 증가 시 다운로드 트래픽/시작 시간이 증가.

실무형 확장으로 가려면:
- S3 + 캐시 프록시(Nginx/CloudFront) 사용
- 또는 RWX 스토리지(EFS/NFS) + PVC 공유

## 6) 공유 스토리지 오버레이 (포트폴리오 추천)

`overlays/shared-storage`는 다음 흐름으로 동작합니다.

1. PVC 생성 (`mfs-data-pvc`, `mfs-models-pvc`)
2. `Job(mfs-sync-assets)`가 Release에서 자산 1회 동기화
3. Deployment는 `wait-assets` initContainer로 준비 완료 마커를 기다린 뒤 앱 시작
4. Replica 2개가 같은 PVC를 마운트해서 실행

적용:

```bash
kubectl apply -k k8s/overlays/shared-storage
kubectl wait --for=condition=complete job/mfs-sync-assets -n mfs --timeout=600s
kubectl rollout status deployment/multimodal-fashion-recommender -n mfs
```

주의:
- k3s 기본 `local-path`는 `ReadWriteOnce`입니다.
- 단일 노드에서는 문제 없지만, 멀티 노드 확장에는 RWX(EFS/NFS) 스토리지 클래스로 바꿔야 합니다.
