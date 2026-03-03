# Production Runbook

## 1. 배포 구성
- App: BentoML API (`:3000`)
- Reverse Proxy: Nginx (`:80/:443`)
- Process manager: `systemd`
- Infra: AWS EC2 Ubuntu 22.04

## 2. 최초 배포
```bash
git clone https://github.com/LeeSY99/multimodal-fashion-recommender-system.git
cd multimodal-fashion-recommender-system
bash infra/scripts/deploy_ec2.sh
bash infra/scripts/install_nginx_ssl.sh <domain> <email>
```

검증:
```bash
systemctl status fashion-search.service
sudo nginx -t
curl -I https://<domain>/ui/
```

## 3. 로그 분석
Nginx:
```bash
sudo tail -f /var/log/nginx/fashion_access.log
sudo tail -f /var/log/nginx/fashion_error.log
```

Systemd / App:
```bash
journalctl -u fashion-search.service -f
docker logs -f $(docker ps --filter "name=multimodal-fashion-search" -q)
```

빠른 상태 진단:
```bash
bash ops/diag.sh <domain>
```

## 4. 장애 대응 시나리오

### Case 1: 동시 요청 시 지연
증상:
- k6에서 `p95 > 1s`, CPU high

확인:
```bash
BASE_URL=https://<domain>/api k6 run loadtest/search.js
```

원인 후보:
- API worker 부족
- CPU saturation

조치:
- BentoML worker 수 증가 (예: `--api-workers 4`)
- EC2 인스턴스 상향

검증:
- 변경 전/후 `p95`, `RPS`, error rate 비교

### Case 2: 메모리 부족
증상:
- OOM kill, 컨테이너 재시작 반복

확인:
```bash
free -h
dmesg -T | grep -i -E "killed process|oom"
docker stats
```

조치:
- swap 2G 추가
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```
- Docker 메모리 제한 설정 (`mem_limit`)

검증:
- OOM 로그 재발 여부, 평균 latency 확인

### Case 3: 포트 충돌
증상:
- 서비스 기동 실패 (`address already in use`)

확인:
```bash
sudo ss -ltnp | grep ':3000\|:80\|:443'
```

조치:
- 충돌 프로세스 확인 후 중지
```bash
sudo kill -15 <pid>
```
- systemd 재기동
```bash
sudo systemctl restart fashion-search.service
```

## 5. 네트워크 트러블슈팅 체크리스트
- Security Group: 22/80/443 open
- NACL/Route table 확인
- DNS A record -> EC2 Public IP
- TLS 인증서 만료일 확인
```bash
echo | openssl s_client -servername <domain> -connect <domain>:443 2>/dev/null | openssl x509 -noout -dates
```
