# Load Test Guide (k6)

## 1) Install
```bash
sudo apt-get update && sudo apt-get install -y gnupg2
curl -s https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install -y k6
```

## 2) Run
```bash
BASE_URL=https://YOUR_DOMAIN/api k6 run loadtest/search.js
```

## 3) KPI
- `p95 < 300ms`
- error rate `< 1%`
- CPU under `70%` during steady state

## 4) Before/After report template
- baseline: worker=1, p95=__ms, rps=__, error=__
- tuned: worker=4, p95=__ms, rps=__, error=__
- change: p95 __% 개선
