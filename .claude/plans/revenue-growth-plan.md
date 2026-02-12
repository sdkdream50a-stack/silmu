# 수익형 전환 추진 계획

> 작성일: 2026-02-11
> 상태: 대기 (천천히 추진)

## 완료 항목 (2026-02-11 배포 완료)

- [x] OfficialDocumentService 캐시 추가 (동일 입력 7일 캐시)
- [x] DocumentAnalyzerService 캐시 만료 24h → 7d 연장
- [x] MCP 확장: Playwright, Context7 추가
- 커밋: `a4d56c6`

---

## 추진 항목 4: 비로그인 미니 도구 + 결과 공유 페이지

### 4-1단계: 계약방식 결정 결과 공유 페이지 (추천 1순위)

**목표**: `GET /tools/contract-method/result?type=goods&price=15000000`

- 입력값을 쿼리 파라미터로 받아 서버사이드 렌더링
- OG 메타 태그 포함 → SNS 공유 시 미리보기
  - 제목: "물품 1,500만원 → 1인 수의계약 가능"
  - 설명: "지방계약법 시행령 제25조 근거, 필요서류 3종..."
- 페이지 하단 "더 많은 도구 사용하기 → 회원가입" CTA
- SEO 효과: 롱테일 키워드 자연 유입

**수정 파일**:
- `config/routes.rb` — result 라우트 추가
- `app/controllers/contract_methods_controller.rb` — result 액션
- `app/views/contract_methods/result.html.erb` — 공유용 결과 페이지 (신규)
- `app/views/sitemap/index.xml.erb` — 사이트맵 등록

### 4-2단계: 예산 간편 진단 독립 페이지

**목표**: `GET /check?type=goods&price=15000000`

- 홈페이지 Quick Price Finder를 독립 페이지로 분리
- 결과: 계약방식 + 필요서류 + 예상 일정 + 법조문 요약
- URL 복사 + 카카오톡 공유 버튼
- AI 호출 없음 (비용 0)

**수정 파일**:
- `config/routes.rb` — /check 라우트
- `app/controllers/home_controller.rb` — check 액션 (또는 신규 컨트롤러)
- `app/views/home/check.html.erb` — 진단 결과 페이지 (신규)

### 4-3단계: AI 도구 1회 체험 (프리미엄 전환 유도)

- 견적서 분석, 공문 생성 등 AI 도구를 비로그인 1회 체험 허용
- 2회부터 가입 유도
- 세션/쿠키 기반 사용 횟수 추적

---

## 추진 항목 5: 지역별 맞춤 가이드 콘텐츠 자동 생성

### 5-1단계: 지역 데이터 구조 설계

```ruby
# Region 모델
create_table :regions do |t|
  t.string :name          # "서울특별시", "경기도 교육청"
  t.string :slug          # "seoul", "gyeonggi-edu"
  t.string :region_type   # "metro", "province", "education"
  t.string :short_name    # "서울시", "경기도교육청"
  t.timestamps
end

# RegionalGuide 모델
create_table :regional_guides do |t|
  t.references :region
  t.references :topic
  t.string :title           # "서울시 수의계약 가이드"
  t.string :slug
  t.text :content           # AI 생성 + 검수 후 저장
  t.text :local_rules       # 해당 지역 특이사항
  t.boolean :published, default: false
  t.timestamps
end
```

### 5-2단계: 시딩 (34개 지역)

- 광역시/도 17개: 서울, 부산, 대구, 인천, 광주, 대전, 울산, 세종, 경기, 강원, 충북, 충남, 전북, 전남, 경북, 경남, 제주
- 교육청 17개: 서울시교육청, 부산시교육청, ...

### 5-3단계: 핵심 토픽별 지역 가이드 (5토픽 x 34지역 = 170페이지)

| 토픽 | 지역 맞춤 포인트 |
|------|-----------------|
| 수의계약 | 지역별 수의계약 심사기준 |
| 입찰 | 지역별 전자입찰 시스템 (서울시 계약시스템 등) |
| 물품구매 | G2B vs S2B vs 자체 시스템 |
| 소액공사 | 지역별 기준금액, 시설과 협의 |
| 예산집행 | 지역별 예산통합정보시스템 |

### 5-4단계: AI 콘텐츠 생성 프로세스

1. 기본 템플릿 (공통 70% + 지역 변수 30%)
2. Claude Haiku로 지역별 변수 자동 채우기
3. public-law-compliance-auditor로 법령 검증
4. published: true 전환

### 5-5단계: URL 구조 및 SEO

```
/regions/seoul/private-contract
/regions/gyeonggi/bidding
/regions/seoul-edu/goods-purchase
```

**수정 파일**:
- `db/migrate/xxx_create_regions.rb`
- `db/migrate/xxx_create_regional_guides.rb`
- `app/models/region.rb`, `app/models/regional_guide.rb`
- `app/controllers/regional_guides_controller.rb`
- `app/views/regional_guides/show.html.erb`
- `db/seeds/regions.rb`
- `app/services/regional_guide_generator.rb`
- `config/routes.rb`
- `app/views/sitemap/index.xml.erb`

---

## 실행 순서

| 순서 | 항목 | AI 비용 | SEO 효과 |
|------|------|---------|----------|
| 1 | 4-1 계약방식 공유 페이지 | 0 | 중 |
| 2 | 4-2 예산 진단 독립 페이지 | 0 | 중 |
| 3 | 5-1,2 지역 DB 구조 + 시딩 | 0 | - |
| 4 | 5-3,4,5 지역 가이드 170개 | 소 (Haiku) | 대 |
| 5 | 4-3 AI 도구 1회 체험 | - | 가입전환 |
