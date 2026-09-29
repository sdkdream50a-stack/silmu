# 감사사례 P2/P3 잔여 정정 — 같은 판정 오류가 FIX 문구 밖 다른 필드에 남은 것 (2026-09-29)
#
# 입력: silmu-audit-case-truth-closure-0929 verdicts.md 의 P2/P3 FIX 가 지적한 오류와 같은 서술이
#   20260929120000(goe)·121000(sen) 이 고친 필드 밖(detail↔lesson)에 한 번 더 있던 것만. 운영 렌더(2026-09-29)에서 확인.
#   beneficiary: 정산·공개 «10일» 합침(현행 규칙 §21 = 정산 10일 + 공개 10일)
#   disposal: «입찰 공고 1주일» = 원문 외 실무 예시
#   failed-bid: 원문 외 «변상 + 징계» (원문 처분 = 관련자 주의)
#   council: «모든 안건 적법성 다툼» 단정 (원문은 효력 판단 안 함)
#   long-term: «입찰 공정성 훼손» (원문 표현 아님)
# 패턴·규칙 = 20260929090000_audit_truth_s.rb (exact-once · 이미 new 면 skip · 불일치 전체 롤백 · DRY_RUN).
# 운영 적용: DRY_RUN=1 → 기대 changes=7 · 재실행 0.

edits = [
  [ "goe-2021-beneficiary-cost-settlement", "detail",
    "점검 과정에서 사업 종료 10일 이내 정산·공개 절차가 누락된 사실이 적발됐습니다.",
    "점검 과정에서 정산(사업 종료 후 10일 이내)·정산내역 공개(정산 후 10일 이내) 절차가 누락된 사실이 적발됐습니다." ],
  [ "goe-2021-disposal-procedure-violation", "detail",
    "입찰 공고 1주일 + 최저 입찰가 산정만 거치면 절차상 안전하며,",
    "입찰 공고와 최저 입찰가 산정 절차를 거치는 것이 원칙이며(공고 기간 «1주일»은 원문 외 실무 예시)," ],
  [ "goe-2021-disposal-procedure-violation", "lesson",
    "- [ ] 매각 공고를 게시판·홈페이지에 1주일 이상 게시했는가?",
    "- [ ] 매각 공고를 게시판·홈페이지에 게시했는가? (공고 기간은 원문에 없음 — 조례·공고문 기준 확인)" ],
  [ "goe-2021-failed-bid-private-contract", "detail",
    "특히 기초금액 인상은 특정 업체 유도 의혹이 가장 강하게 제기되는 패턴이며, 사후 적발 시 행정실장 본인이 변상 책임 + 징계 동시 대상이 될 수 있습니다.",
    "특히 기초금액 인상은 특정 업체 유도 의혹을 받기 쉬운 패턴입니다(원문 처분: 관련자 주의)." ],
  [ "goe-2021-failed-bid-private-contract", "lesson",
    "인상 폭이 크지 않더라도 (2,000천원 같은 작은 인상도) 의도성 입증 자료가 되며, 행정실장은 변상 책임 + 견책 이상 징계 대상이 될 수 있습니다.",
    "인상 폭이 크지 않더라도(원문 사례는 2,000천원 인상) 최초 조건 변경에 해당해 부적정 수의계약으로 지적됩니다(원문 처분: 관련자 주의)." ],
  [ "sen-2025-school-c-school-council-composition", "lesson",
    "\"지역위원 1명 빠진 채로 회의\" = 학교운영위 자체가 자격 미비 → **그 회의에서 심의된 모든 안건 적법성 다툼 가능**. 학교회계 예결산이 학교운영위 심의 사항이므로 구성 부적정은 학교회계 자체에 영향.",
    "\"지역위원 1명 빠진 채로 회의\" = 구성 부적정 상태의 회의 개최로 지적됨(초·중등교육법 §34·시행령 §63, 기관주의). 원문은 회의·심의의 효력(무효)은 판단하지 않았습니다." ],
  [ "sen-2025-school-c-long-term-contract-violation", "lesson",
    "2년 입찰은 법령 위반 + 입찰 공정성 훼손 (기초금액 산정 왜곡).",
    "원문은 2년 입찰에 기초금액을 1개 연도분으로 산정하는 등 관련 규정에 위배된다고 지적했습니다." ]
].freeze

count_in = lambda do |value, needle|
  case value
  when String then value.scan(needle).size
  when Array  then value.sum { |v| count_in.call(v, needle) }
  when Hash   then value.values.sum { |v| count_in.call(v, needle) }
  else 0
  end
end

slugs = edits.map(&:first).uniq
dry = ENV["DRY_RUN"] == "1"
changes = 0
ActiveRecord::Base.transaction(requires_new: true) do
  slugs.each do |slug|
    record = AuditCase.find_by(slug: slug)
    raise "[audit-truth-p2p3-residual] missing case: #{slug}" unless record

    to_write = {}
    edits.select { |s, _, _, _| s == slug }.map { |_, f, _, _| f }.uniq.each do |field|
      original = record.read_attribute(field)
      value = original
      edits.select { |s, f, _, _| s == slug && f == field }.each do |_, _, old, new|
        next if count_in.call(value, new).positive? && count_in.call(value, old).zero?
        raise "[audit-truth-p2p3-residual] fingerprint missing: #{slug}/#{field}: #{old[0, 40]}" unless count_in.call(value, old) == 1

        value = value.gsub(old) { new }
        changes += 1
      end
      to_write[field] = value unless value == original
    end
    next if to_write.empty?

    puts "  [audit-truth-p2p3-residual] AuditCase/#{slug} fields_to_change=#{to_write.keys.join(',')}"
    record.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end
puts "  [audit-truth-p2p3-residual] #{"DRY_RUN " if dry}changes=#{changes}"
