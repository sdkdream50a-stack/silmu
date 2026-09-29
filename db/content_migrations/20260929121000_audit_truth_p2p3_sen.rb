# 감사사례(서울시교육청 2025 사립 종합감사 공개문) 원문 대조 정정 — P2/P3 batch SEN (2026-09-29)
#
# 입력: tasks/silmu-audit-case-p2p3-closure-0929/sources/p2p3_verdict_blocks.md 의 sen-2025-* P2·P3 블록(FIX·EVIDENCE)만.
#   P2 2건: school-i-split-private-disability(예규 번호 · «처분 강도 더 높음»·«적발 흔적»·«설계+공사 동일 사업» 근거 없음)
#           school-c-facility-design-document(근거 법령란에 분할수의계약 지적 근거 누락)
#   P3 12건: 원문에 없는 단정(무효·형사책임·횡령·계약 무효화·공정성 훼손) · 내부 참조 문구(«메모리 #9») · 조문 호수(영 §26①) · 원문 정확값
#   적용하지 않는 것: action_taken(조치내용) · «(선택)» FIX · 목록 밖 P0/P1 사례 · slug/title/view_count/target_agency(FIX 에 기관 혼재 지적 없음).
#
# 원문: 서울특별시교육청 감사관 종합감사 결과 공개문 2025 — Y학원·Y여고 · I고 · C학원·C여고 · C고 · V간호비즈니스고 · S학원·S고.
# 현행 법령(블록 LAW_CURRENT, 2026-09-29): 국가계약법 시행령 제26조①(제1~5호) · 지방자치단체 입찰 및 계약 집행기준 = 행정안전부 예규 제372호(2026.7.1.)
#   · 전기공사업법 제11조①③·시행령 제8조 · 산업안전보건법 제73조 · 사학기관 재무·회계 규칙 제41조②(기한 규정 없음).
#
# old 는 운영 페이지(https://silmu.kr/audit-cases/<slug>, 2026-09-29 익명 GET)의 렌더 문자열과 같다(마크다운 기호 제외).
# 필드에 old 가 정확히 1회 있어야 바꾼다. 이미 new 면 건너뛴다. 하나라도 어긋나면 전체 롤백.
# DRY_RUN=1 이면 레코드별 fields_to_change 만 출력. slug·title·view_count·target_agency 불변.
#
# 운영 적용(배포 후):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20260929121000_audit_truth_p2p3_sen.rb})"'
#   → 기대: changes=24 · 두 번째 실행 changes=0
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화)
# 롤백: new → old 역적용.

edits = [
  # ── Y학원 임시감사 누락: 원문에 없는 «14일 이내»·공립 «학교법인»·내부 참조 문구 ─────────
  [ "sen-2025-foundation-y-audit-omission", "detail",
    "이는 회계관계직원 인계인수(메모리 #9 사례 참조) 누락과 결합되면",
    "이는 회계관계직원 인계인수 누락과 결합되면" ],
  [ "sen-2025-foundation-y-audit-omission", "lesson",
    "silmu 실무: 학교법인 정관에 \"회계관계직원 변경 시 14일 이내 감사 의무\" 명시 권장. 공립학교 법인은 별도이지만 동일 원리(교육청 자체감사 규정 적용).",
    "silmu 실무: 사학기관 재무·회계 규칙 §41②는 이 감사의 기한을 정하지 않음." ],

  # ── Y여고 인계인수: «11회 누락» 합산 표현 · 공립 «동일» 근거 없음 ──────────────
  [ "sen-2025-school-y-handover", "detail",
    "누적 위반: 회계관계직원 10차례 + 발전기금 출납명령기관 1차례 = 11회 인계인수 누락.",
    "누적 위반(인계인수): 회계관계직원 10차례 미작성 + 발전기금 출납명령기관 1건 소홀." ],
  [ "sen-2025-school-y-handover", "lesson",
    "책임소재 불명확. 공립학교 행정실도 동일(학교회계 규칙). 회계관계직원·",
    "책임소재 불명확. 회계관계직원·" ],

  # ── I고 분할수의(P2): 예규 번호 · 원문 처분(주의)과 모순 · 근거 없는 적발·해석 문장 ──
  [ "sen-2025-school-i-split-private-disability", "legal_basis",
    "지방자치단체 입찰 및 계약집행기준(행정안전부 예규 제332호) 제1장",
    "지방자치단체 입찰 및 계약집행기준(행정안전부 예규 — 원문 제324호; 현행 제372호, 2026.7.1.) 제1장" ],
  [ "sen-2025-school-i-split-private-disability", "detail",
    "- 동일 장애인기업과 1인 수의계약 2건 체결\n\n이는 장애인기업 우대 제도 자체를 악용한 것으로 처분 강도 더 높음.",
    "- 동일 장애인기업과 1인 수의계약 2건 체결" ],
  [ "sen-2025-school-i-split-private-disability", "lesson",
    "무력화. 감사관은 단일 설계서·동일 도면·동일 시점 발주 흔적으로 분할 적발. silmu 실무:",
    "무력화. silmu 실무:" ],
  [ "sen-2025-school-i-split-private-disability", "lesson",
    "사전 협의 권장. 특히 건축 설계+공사는 동일 사업으로 본다는 해석.",
    "사전 협의 권장." ],

  # ── C여고 발전기금: «횡령 의혹» 과장 ───────────────────────────────────────
  [ "sen-2025-school-c-development-fund-misuse", "lesson",
    "외 사용 시 횡령 의혹.",
    "외 사용 시 요령 위반(목적 외·제한 항목 사용)." ],

  # ── C여고 전기공사 분리발주: «무자격 = §3 위반»·«형사책임 직결» 원문 없음 ─────────
  [ "sen-2025-school-c-electrical-separate-order", "detail",
    "- 즉 건축업자가 무자격으로 전기공사 시공 = §3 위반",
    "- 전기공사는 다른 업종 공사와 분리발주(법 §11①); 예외는 법 §11③·시행령 §8" ],
  [ "sen-2025-school-c-electrical-separate-order", "lesson",
    "**전기공사는 법적으로 분리발주 강제**. 무자격 전기 시공은 화재·감전 사고 시 학교장 형사책임 직결. 시공 단계가",
    "**전기공사는 법적으로 분리발주 강제**. 시공 단계가" ],

  # ── C여고 학교운영위 구성: 원문에 없는 «무효» 단정 · 사립 = 교비회계 ─────────────
  [ "sen-2025-school-c-school-council-composition", "detail",
    "- 1종 누락 시 운영위 자체 무효",
    "- 원문은 지역위원 미구성 상태 정기회 개최를 초·중등교육법 §34·시행령 §63 위반으로 지적(기관주의)했을 뿐 회의·심의의 효력(무효)은 판단하지 않음" ],
  [ "sen-2025-school-c-school-council-composition", "detail",
    "- 학교운영위는 학교회계 예결산 심의 기관\n- 구성 부적정 상태 회의 = 심의 자체 무효 → 학교회계 적법성 위협",
    "- 사립학교 운영위는 교비회계 예·결산 심의 기관" ],

  # ── V고 성립 전 예산 집행: 회계연도 모호 표현 · 교부 예정/실제 구분(원문 각주 1) ──────
  [ "sen-2025-school-v-budget-pre-execution", "issue",
    "실제 예산 교부는 2025.3.12. 예정이었음.",
    "예산 교부 안내는 2025년 3월 예정이었고, 실제 교부는 2025.3.12.에 이루어짐." ],
  [ "sen-2025-school-v-budget-pre-execution", "detail",
    "- 학교: 2024년도(회계연도) 1월에 공사 계약·시행",
    "- 학교: 2024회계연도에 속하는 2025년 1월(회계연도 3.1~익년 2.28)에 공사 계약·시행" ],

  # ── V고 시설공사 분할수의: 영 §26① 호수 · 원문에 없는 예정가격 규칙 ──────────────
  [ "sen-2025-school-v-facility-split-private", "detail",
    "시행령 §26 1~7호 예외 사유",
    "시행령 §26①각 호(현행 제1~5호) 예외 사유" ],
  [ "sen-2025-school-v-facility-split-private", "lesson",
    "— 설계금액과 예정가 격차를 감사관이 즉시 확인. 예정가격은 설계금액·시장조사·관급자재 등을 종합하여 산정 의무. 예정가 임의 조정은 §26 위반 + 입찰 공정성 훼손 이중 위반. silmu 실무:",
    "— 원문은 설계금액 5천만 원 초과에도 예정가격을 낮춰 1인 수의계약한 사실을 지적. silmu 실무:" ],

  # ── Y디자인고 업무용차량: «무상 대여»·«즉시» 원문 표현 아님 ──────────────────────
  [ "sen-2025-school-y-vehicle-leave-violation", "lesson",
    "한 학교 차량을 타교 업무에 무상 대여하면 즉시 §29 위반.",
    "원문: 회계와 재산이 분리된 타학교 교직원의 업무에 본교 교비 구입 차량을 이용하게 한 사실(사립학교법 §29 교비회계 전출·대여·목적 외 사용 금지 원칙)." ],

  # ── S고 재해예방 기술지도: 형사책임·발주자 책임 가중 원문·법령 인용 없음 ──────────────
  [ "sen-2025-school-s-disaster-prevention", "lesson",
    "재해예방 기술지도 누락 시 산재 사고 발생 시 학교장 형사책임 + 산재보험 청구 시 발주자 책임 가중.",
    "재해예방 기술지도계약 미체결은 산안법상 기술지도계약 체결 의무(산안법 §73) 위반." ],

  # ── S고 용역계약: 영 §26① 호수 · 원문 정확값 ─────────────────────────────────
  [ "sen-2025-school-s-service-contract-violation", "detail",
    "- 2022: 9,400만 원 거래",
    "- 2022: 94,297,000원 거래" ],
  [ "sen-2025-school-s-service-contract-violation", "lesson",
    "시행령 §26 1~7호 한정",
    "시행령 §26①각 호(현행 제1~5호) 한정" ],

  # ── S고 물품구매: «계약 무효화 위험» 원문·법령 근거 없음 ─────────────────────────
  [ "sen-2025-school-s-supply-direct-prod-cert", "detail",
    "+ 직접생산확인 미확인 = 위장 직접생산 발견 시 계약 무효화 위험.",
    "+ 직접생산확인 미확인." ],

  # ── C고 설계도서(P2): 근거 법령란에 분할수의계약 지적 근거 추가(원문 p.9-10) ──────────
  [ "sen-2025-school-c-facility-design-document", "legal_basis",
    "사립학교 시설사업비 지원기준 및 집행지침(서울시교육청 교육시설안전과)",
    "사립학교 시설사업비 지원기준 및 집행지침(서울시교육청 교육시설안전과), 사학기관 재무·회계 규칙 제4조·제35조, 국가를 당사자로 하는 계약에 관한 법률 제7조, 같은 법 시행령 제26조·제30조·제68조(분할수의계약 지적)" ],

  # ── C고 장기계속계약: «입찰 공정성 훼손» 원문 표현 아님 ──────────────────────────
  [ "sen-2025-school-c-long-term-contract-violation", "detail",
    "- 기초금액도 1년분만 산정 → 입찰 공정성 훼손",
    "- 원문: 기초금액을 2년 총액이 아닌 1개 연도분으로 산정하는 등 관련 규정에 위배" ]
].freeze

count_in = lambda do |value, needle|
  case value
  when String then value.scan(needle).size
  when Array  then value.sum { |v| count_in.call(v, needle) }
  when Hash   then value.values.sum { |v| count_in.call(v, needle) }
  else 0
  end
end

replace_in = lambda do |value, from, to|
  case value
  when String then value.gsub(from) { to }
  when Array  then value.map { |v| replace_in.call(v, from, to) }
  when Hash   then value.transform_values { |v| replace_in.call(v, from, to) }
  else value
  end
end

slugs = edits.map(&:first).uniq
dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  slugs.each do |slug|
    record = AuditCase.find_by(slug: slug)
    raise "[audit-truth-p2p3-sen] missing case: #{slug}" unless record

    to_write = {}
    edits.map { |_, f, _, _| f }.uniq.each do |field|
      original = record.read_attribute(field)
      value = original
      edits.select { |s, f, _, _| s == slug && f == field }.each do |_, _, old, new|
        # 이미 적용됨: new 가 있고 old 가 없거나, new 가 old 를 품는 덧붙임형 edit
        next if count_in.call(value, new).positive? && (count_in.call(value, old).zero? || new.include?(old))
        raise "[audit-truth-p2p3-sen] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

        value = replace_in.call(value, old, new)
        changes += 1
      end
      to_write[field] = value unless value == original
    end
    next if to_write.empty?

    puts "  [audit-truth-p2p3-sen] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    record.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-truth-p2p3-sen] #{"DRY_RUN " if dry}changes=#{changes}"
