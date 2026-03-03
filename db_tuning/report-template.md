# DB Tuning Report

## 환경
- DB: PostgreSQL 16
- 데이터: 200,000 rows
- 인스턴스: (예: EC2 t3.medium)

## Query A
- 목적: 카테고리별 상위 상품 조회
- Before: __ ms
- After: __ ms
- 개선율: __ %
- Plan 변화: Seq Scan -> Index Scan (Yes/No)

## Query B
- 목적: 키워드 검색 + 정렬
- Before: __ ms
- After: __ ms
- 개선율: __ %
- Plan 변화: Seq Scan -> Bitmap Index Scan (Yes/No)

## 해석
- 병목 원인:
- 적용한 인덱스:
- 비용 대비 효과:

## 재발 방지 / 확장
- slow query log 임계치
- 정기 ANALYZE/VACUUM 정책
