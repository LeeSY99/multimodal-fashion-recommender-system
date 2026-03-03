# DB Tuning Lab (PostgreSQL)

## 목적
- 20만 건 데이터에서 인덱스 전/후 성능 차이를 수치로 기록
- `EXPLAIN (ANALYZE, BUFFERS)` 기반으로 실행계획 해석

## 실행
```bash
cd db_tuning/postgres
docker compose up -d
```

자동 실행:
```bash
bash db_tuning/run_lab.sh
```

```bash
psql "postgresql://fashion:fashion@localhost:5432/fashion" -f 03_benchmark_before.sql
psql "postgresql://fashion:fashion@localhost:5432/fashion" -f 04_add_indexes.sql
psql "postgresql://fashion:fashion@localhost:5432/fashion" -f 05_benchmark_after.sql
```

## 확인 포인트
- Sequential Scan -> Index Scan 전환 여부
- 총 실행시간(ms) 변화
- Buffers hit/read 감소 여부

## 산출물
- `db_tuning/report-template.md` 작성
