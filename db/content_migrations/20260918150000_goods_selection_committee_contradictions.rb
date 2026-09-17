# 물품선정위원회 토픽 내부 모순·허위 근거 정정 (2026-09-18 연수 P0-5 · LECTURE_READINESS_AUDIT R3)
#
# ── 원문 대조로 확정한 사실 (2026-09-18)
#   · 행안부 「지방자치단체 입찰 및 계약집행기준」(2026.7.1 · 원문 810KB)에
#     «물품선정위원회» 0건 · «물품선정» 0건. «선정위원회» 14건은 **전부 공법선정위원회**
#     (신기술·특허공법 선정, 제3관 구성·운영)로 별개 기구다.
#   · 지방계약법·시행령 전문에도 «물품선정위원회» 0건.
#   · 종전 이 탭이 근거로 들던 「지방계약법 시행령」 **제43조는 현행 시행령에 없다**
#     (titles·articles 모두 42 다음이 44. 양성 대조 = 제25조 수의계약·제30조 선정절차·
#      제42조 낙찰자 결정·제44조 지식기반사업·제77조 분할계약 금지는 전부 정상 조회됨).
#   · 법정 기구는 **계약심의위원회**: 법 제32조(설치·운영) · 시행령 제106조(구성)·
#     제106조의2(위원 해촉)·제107조(운영)·제108조(심의대상)·제109조(세부사항). 별개 기구다.
#   · 법 제9조의2 = 구매규격 사전공개 ✓ (law_content 의 인용은 정확 — 건드리지 않는다).
#
# ── 내부 모순 (같은 페이지에서 서로 다른 값을 말하고 있었다)
#   의무 개최 금액: decree 500만원 / qa 3,000만원 / interpretation 2억원 / commentary·faqs 500만원
#   구성 인원:     decree 3~5명 / regulation 최소 5인 이상 / qa 통상 5명 이상 / tips·faqs 3~5인
#   소집 통보:     rule 3일 전 / regulation 7일 전 / tips 3일 전
#   법적 성격:     law·commentary·faqs «법적 의무 아님 · 내부 규정» ↔ regulation «시행령 §43·
#                  물품관리법·행안부 예규에 근거» ↔ interpretation «심의 결과는 구속력»
#
# ── 방침
#   숫자를 «옳은 숫자»로 바꾸지 않는다 — 어느 숫자도 공식 근거가 없다.
#   기관 자치법규·교육청 지침 사항이라는 사실만 남기고 수치 단정을 제거한다.
#   유권해석 4건은 원문 미확인이라 라벨을 낮추고(G-38 선례), 허위 단정 3개만 정정한다.
#
# 하나라도 지문이 맞지 않으면 전체 롤백한다. DRY_RUN=1 이면 쓰지 않는다.

SLUG = "goods-selection-committee"

REGULATION_FINGERPRINT = "e479a3d0dda2be29b5392a78f042a89adf4656838453756c9359a1fb00b6b5c9"

REGULATION_NEW = <<~MD.strip
  ## 근거 확인 결과 — 법정 위원회가 아니다

  **물품선정위원회는 법령·행안부 예규에 규정된 위원회가 아니다.** 2026-09-18 원문 대조 결과는 다음과 같다.

  | 확인 대상 | 결과 |
  |---|---|
  | 행안부 「지방자치단체 입찰 및 계약집행기준」(2026.7.1) | «물품선정위원회» **0건** |
  | 「지방자치단체를 당사자로 하는 계약에 관한 법률」 | «물품선정위원회» **0건** |
  | 같은 법 시행령 | «물품선정위원회» **0건** |

  집행기준에 나오는 «선정위원회»는 **공법선정위원회**(공사에 적용할 신기술·특허공법을 선정하는 위원회)로, 물품 규격을 심의하는 이 위원회와는 다른 기구다.

  ### 법정 위원회는 «계약심의위원회»다 — 별개 기구

  - 「지방계약법」 제32조(계약심의위원회의 설치ㆍ운영)
  - 같은 법 시행령 제106조(구성)·제106조의2(위원의 해촉)·제107조(운영)·제108조(심의대상)·제109조(구성과 운영 등에 필요한 세부사항)

  계약심의위원회는 심의대상·구성·운영이 법령에 정해져 있다. 물품 규격을 정하려고 여는 물품선정위원회를 계약심의위원회와 같은 것으로 다루면 안 된다.

  ### 그러면 무엇이 근거인가

  물품선정위원회는 **소속 기관의 자치법규(조례·규칙)와 상급기관·교육청 지침**에서 정한다. 따라서 이 페이지는 **개최 의무 금액·위원 수·소집 통보 기한을 기준으로 제시하지 않는다.** 그 값은 기관마다 다르며, 기관 규정 원문에서 확인해야 한다.

  학교·교육행정의 경우 시도교육청의 물품 관리·구매 관련 지침이 적용되므로, 지방자치단체 규정을 그대로 준용하지 않는다.

  ### 종전 서술에서 삭제한 것 (2026-09-18)

  이 탭은 «행정안전부 예규 제1장~제4장» 형식으로 조문 구조를 제시하고 「지방계약법 시행령」 제43조·「물품관리법」을 근거로 들고 있었다. 집행기준 원문에 그런 장 구조가 없고, **현행 시행령에는 제43조 자체가 없으며**(제42조 다음이 제44조), 「물품관리법」을 이 위원회의 근거로 든 부분도 원문에서 확인되지 않았다. 확인되지 않은 근거를 표기하지 않기 위해 삭제했다.
MD

# [필드, 지문, old, new] — old 는 해당 필드에 정확히 1회만 있어야 한다(사전 실측 완료).
SUBSTITUTIONS = [
  # ── decree 탭: 법정 기준처럼 읽히는 제목과 출처 없는 수치
  [ :decree_content, "6bf85aae1212b1a5e6460790b604a916192263d368a972d06efcbedbcc577193",
    "## 물품선정위원회 구성 및 운영 기준",
    "## 물품선정위원회 구성·운영 — 기관 규정 예시 (법정 기준 아님)" ],
  [ :decree_content, nil,
    "### 개최 기준 (일반적 기준)",
    "### 개최 기준 — 값은 기관 규정에서 정한다" ],
  [ :decree_content, nil,
    "| 의무 개최 | 추정가격 **500만원** 이상 | 기관별 내부 규정 확인 |",
    "| 의무 개최 | **소속 기관 규정에서 정한 금액 이상** | 법령·예규에 정해진 금액이 없다. 기관 조례·규칙·교육청 지침 원문 확인 |" ],
  [ :decree_content, nil,
    "| **합계** | **3~5명** | 홀수 권장 (의결 편의) |",
    "| **합계** | **기관 규정에서 정한 인원** | 법령에 정해진 인원이 없다. 홀수 구성은 가부동수를 피하는 실무 편의일 뿐이다 |" ],

  # ── rule 탭: 소집 통보 기한 (regulation 7일 전과 충돌했다)
  [ :rule_content, "bb69a2bdacacf736c659562e227559dcc0c4857f604cf118c247842c65c0886b",
    "| 3단계 | 위원회 소집 (3일 전 통보) | 소집 공문 |",
    "| 3단계 | 위원회 소집 (통보 기한은 기관 규정에 따름) | 소집 공문 |" ],

  # ── practical_tips 체크리스트: 같은 수치 반복
  [ :practical_tips, "efafb2d7e45c6b84217cb8806b9e0de02b5ea22ddd6f9859ebafb6fed8c7787b",
    "- [ ] 위원회 구성 (3~5인)",
    "- [ ] 위원회 구성 (인원은 기관 규정 확인)" ],
  [ :practical_tips, nil,
    "- [ ] 위원회 소집 통보 (3일 전)",
    "- [ ] 위원회 소집 통보 (기한은 기관 규정 확인)" ],

  # ── qa 탭: 3,000만원·5명 이상·외부 1/3 — 다른 탭과 전부 충돌
  [ :qa_content, "78c7adff87c293c65ddad26f53b6927065aab97623dc00471068d911f1231f74",
    "추정가격 **3,000만원 이상** 물품 구매 시 내부 심의위원회 구성 (기관 규정에 따라 상이)",
    "**소속 기관 규정에서 정한 금액 이상** 물품 구매 시 내부 심의위원회 구성 (법령·예규에 정해진 금액이 없어 기관마다 다르다)" ],
  [ :qa_content, nil,
    "위원 수: 통상 5명 이상 (홀수 구성 권장 — 가부 동수 방지)",
    "위원 수: 기관 규정에서 정한다 (홀수 구성은 가부동수를 피하는 실무 편의)" ],
  [ :qa_content, nil,
    "외부위원 비율: 전체의 1/3 이상 권장",
    "외부위원 비율: 기관 규정에서 정한다 (법령·예규에 정해진 비율이 없다)" ],

  # ── interpretation 탭: 출처 미확인 «유권해석» 4건 → 라벨 강등 + 허위 단정 3개 정정
  [ :interpretation_content, "989823087acdb8672971b03e3a4e4b8118b7d6540abac336bf58e46cff0aa8b3",
    "## 유권해석 사례",
    "## 실무 판단 예시 — 유권해석 원문 미확인\n\n아래 4건은 실무에서 자주 묻는 상황과 일반적 판단 방향을 정리한 **예시**다. 행정안전부 유권해석 원문을 확인하지 못했으므로 유권해석으로 인용하지 말고, 소속 기관 규정과 상급기관 질의로 확정하라." ],
  [ :interpretation_content, nil,
    "물품선정위원회의 심의 결과는 구매 담당 부서를 구속하는 효력을 가집니다.",
    "물품선정위원회는 법정 위원회가 아니어서 심의 결과의 구속력은 **그 기관의 규정이 어떻게 정하는지에 달려 있습니다**(법령에 구속력 규정이 없습니다)." ],
  [ :interpretation_content, nil,
    "행정안전부 예규에서는 외부 전문가 참여를 권장하고 있으나,",
    "행안부 집행기준 원문에는 물품선정위원회 규정 자체가 없어 외부 전문가 참여 요건도 **기관 규정 사항**이나," ],
  [ :interpretation_content, nil,
    "추정가격 2억 원 이상의 물품 구매에서 특정 규격 또는 업체를 선정하는 경우에는 원칙적으로 위원회 심의를 거쳐야 합니다.",
    "규격을 특정하거나 업체를 지정하게 되는 구매는 금액과 무관하게 심의를 거치는 것이 안전하며, 심의 의무 금액은 기관 규정에서 확인해야 합니다." ],
  [ :interpretation_content, nil,
    "(행정안전부 유권해석)",
    "(실무 예시 — 유권해석 원문 미확인)" ]
]

# faqs 는 JSONB 이고 **FAQPage 구조화 데이터로도 노출**된다 — 검색 결과에 그대로 나간다.
#   그래서 본문 탭과 같은 축(금액·인원)을 여기서도 닫는다.
#   (통합 스모크에서 이 면이 먼저 잡혔다 — 뷰만 고치고 JSONB·메타를 놓쳤다.)
FAQS_FINGERPRINT = "98945f094e7b1d27265b30aba902bb92e067b5d5568f9d21d122d00c9eb1722f"

FAQ_SUBSTITUTIONS = [
  [ "법적 의무는 아니지만, 대부분의 기관에서 500만원 이상 물품 구매 시 내부 규정으로 의무화하고 있습니다.",
    "법적 의무는 아닙니다. 개최 의무 금액은 기관마다 내부 규정으로 정하므로, 소속 기관 규정을 확인해야 합니다(법령·예규에 정해진 금액이 없습니다)." ],
  [ "3~5명이 일반적이며, 홀수로 구성하는 것을 권장합니다.",
    "법령에 정해진 인원이 없습니다 — 기관 규정에서 정합니다. 홀수 구성은 가부동수를 피하는 실무 편의입니다." ]
].freeze

# commentary 는 «법적 의무가 아니라 내부 규정» 이라고 정직하게 말하는 탭이라 구조는 유지한다.
#   다만 출처 없는 «일반적으로 500만원» 만 남아 다른 탭과 다시 충돌하므로 그 두 문장만 중립화한다.
COMMENTARY_FINGERPRINT = "54b68d9bd7b0cb5511283251048f0b3653c774a8d9bbda46b338bf199dccdca3"

COMMENTARY_SUBSTITUTIONS = [
  # ⚠️ 원문에 <strong> 태그가 끼어 있다 — 태그를 빼고 매칭하려다 «not found once» 로 막혔다.
  #    지문 가드가 조용한 부분적용 대신 정직하게 실패했다.
  [ "일반적으로 <strong>500만원 이상</strong> 물품 구매 시 개최하도록 내부 규정을 두고 있습니다.",
    "개최 기준 금액은 <strong>기관마다 내부 규정으로 정합니다</strong> — 법령·예규에 정해진 금액이 없습니다." ],
  [ "• 소액 (기관별 기준, 보통 500만원 미만)",
    "• 소액 (기준 금액은 기관 규정에서 확인)" ]
].freeze

dry = ENV["DRY_RUN"] == "1"
changes = 0

ActiveRecord::Base.transaction do
  topic = Topic.find_by(slug: SLUG)
  raise "[goods-committee] topic missing: #{SLUG}" if topic.nil?

  # 1) regulation_content 전체 교체 (허위 근거 구조라 문장 치환으로는 닫히지 않는다)
  current = topic.regulation_content.to_s
  if current != REGULATION_NEW
    unless Digest::SHA256.hexdigest(current) == REGULATION_FINGERPRINT
      raise "[goods-committee] regulation_content fingerprint mismatch"
    end

    topic.update_columns(regulation_content: REGULATION_NEW, updated_at: Time.current) unless dry
    changes += 1
  end

  # 2) 나머지 탭은 문장 단위 치환. 지문이 주어진 첫 항목에서 필드 전체를 한 번 검증한다.
  SUBSTITUTIONS.each do |column, fingerprint, old, new|
    text = topic.reload.public_send(column).to_s

    if fingerprint && !text.include?(new)
      unless Digest::SHA256.hexdigest(text) == fingerprint
        raise "[goods-committee] #{column} fingerprint mismatch"
      end
    end

    # 이미 적용된 경우(재실행) — 새 문구가 있고 옛 문구가 없으면 건너뛴다.
    next if text.include?(new) && !text.include?(old)

    occurrences = text.scan(old).size
    # «(행정안전부 유권해석)» 만 4회 반복이고 나머지는 1회다 — 수를 단정해서 조용한 부분적용을 막는다.
    expected = old == "(행정안전부 유권해석)" ? 4 : 1
    unless occurrences == expected
      raise "[goods-committee] #{column}: expected #{expected} occurrence(s) of #{old[0, 40].inspect}, found #{occurrences}"
    end

    replaced = text.gsub(old) { new }
    raise "[goods-committee] #{column}: substitution did not apply" if replaced == text

    topic.update_columns(column => replaced, updated_at: Time.current) unless dry
    changes += 1
  end

  # 3) faqs (JSONB) — 배열 안 answer 문자열을 치환한다.
  faqs = topic.reload.faqs
  if faqs.present?
    raw = faqs.to_json
    pending = FAQ_SUBSTITUTIONS.reject { |old, new| raw.include?(new) && !raw.include?(old) }
    if pending.any?
      unless Digest::SHA256.hexdigest(raw) == FAQS_FINGERPRINT
        raise "[goods-committee] faqs fingerprint mismatch"
      end

      updated = faqs.map do |entry|
        e = entry.dup
        answer = e["answer"].to_s
        pending.each do |old, new|
          next unless answer.include?(old)

          answer = answer.sub(old) { new }
        end
        e["answer"] = answer
        e
      end
      raise "[goods-committee] faqs substitution did not apply" if updated.to_json == raw

      pending.each do |old, _|
        raise "[goods-committee] faqs still contains #{old[0, 30].inspect}" if updated.to_json.include?(old)
      end

      topic.update_columns(faqs: updated, updated_at: Time.current) unless dry
      changes += pending.size
    end
  end

  # 4) commentary — 출처 없는 500만원 단정 2문장만.
  commentary = topic.reload.commentary.to_s
  pending_c = COMMENTARY_SUBSTITUTIONS.reject { |old, new| commentary.include?(new) && !commentary.include?(old) }
  if pending_c.any?
    unless Digest::SHA256.hexdigest(commentary) == COMMENTARY_FINGERPRINT
      raise "[goods-committee] commentary fingerprint mismatch"
    end

    replaced = commentary.dup
    pending_c.each do |old, new|
      raise "[goods-committee] commentary: #{old[0, 30].inspect} not found once" unless replaced.scan(old).size == 1

      replaced = replaced.sub(old) { new }
    end
    raise "[goods-committee] commentary substitution did not apply" if replaced == commentary

    topic.update_columns(commentary: replaced, updated_at: Time.current) unless dry
    changes += pending_c.size
  end
end

puts "  [goods-committee] #{"DRY_RUN " if dry}changes=#{changes}"
