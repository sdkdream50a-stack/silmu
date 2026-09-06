# frozen_string_literal: true

#
# 배포 blocker 정정 — 운영 DB **기존 row 갱신**
# 2026-09-06. 독립검증(agy)이 MUST_FIX_BEFORE_DEPLOY 로 판정한 F1·F2·F3·F5 + 앞 라운드 B1·B2.
#
# ⚠️ 이 시드가 존재하는 이유 자체가 F3 이다.
#   원천 시드(`db/seeds/audit_cases/topic_audit_cases_batch_01.rb` 등)는 `find_or_create_by!` 라서
#   **이미 적재된 운영 row 를 갱신하지 않는다.** 원천만 고치면 운영 콘텐츠는 그대로다.
#   그래서 여기서는 create 를 하지 않고 `find_by` + `save!` 로 **UPDATE 경로만** 쓴다.
#   row 가 없으면 만들지 않고 missing 으로 보고한다 — 없는 row 를 새로 만들어 통과시키면 실패다.
#
# 정본 (law.go.kr 실측 2026-09-06 · docs/silmu-p2/r2-align/_data/sources_verified.json):
#   §25①1호 = 천재지변·감염병… 입찰에 부칠 여유가 없는 경우   ← «소액 수의계약» 이 아니다
#   §25①5호 = 소액 수의계약 체계 (가목 공사 4억/2억/1.6억 · 나목 물품·용역 2천만 ·
#             다목 청년창업 5천만 · 라목 소기업·소상공인 1억 · 마목 1억 · 바목 여성·장애인·사회적기업 등 1억)
#   → 한도는 **계약유형과 상대방 요건에 따라 갈린다.** 하나의 숫자·하나의 호로 단정하면 틀린다.
#
# F2 — `verification_source` 는 `legal_basis` 에서 **파생 생성돼 영구 저장**된다
#   (`db/seeds/zz_auditcase_verification_2026_06_18_batch14.rb`). legal_basis 만 고치면
#   검증 근거가 옛 조문을 가리킨 채 남는다. 그래서 **같은 생성 계약을 재사용**해 다시 만든다.
#   임의 문자열 치환으로 만들지 않는다.
#
# 적용: kamal app exec --reuse 'bin/rails runner "load Rails.root.join(%q{db/seeds/topic_deploy_blocker_fix_2026_09_06.rb})"'
# DRY-RUN: SILMU_SEED_DRY_RUN=1 로 같은 파일을 실행하면 쓰기 없이 갱신 예정 건수만 센다.
# 멱등: 이미 정정된 row 는 old 문자열 부재 → 갱신 대상에서 빠진다(두 번째 실행 updated=0).
#

# 상수 재정의 경고를 피하고, 테스트가 모듈만 로드해 직접 apply! 할 수 있게 한 번만 정의한다.
module SilmuDeployBlockerFix20260906
  # zz_auditcase_verification_2026_06_18_batch14.rb 의 생성 계약을 그대로 재사용한다.
  VS_PREFIX = "공개 감사패턴 일반화(silmu 시드, 특정 실사례 아님). law.go.kr 검증 근거: "
  VS_SUFFIX = ". 운영 정합"
  VS_MAX    = 200

  HO5_LOCATOR = "제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인)"

  # ── AuditCase: slug → [필드 무관 전역 치환쌍] ────────────────
  AUDIT_SUBS = {
    # B1 — 「수의계약 한도 = 5천만원」 보편 단정 5곳. 다른 단일 숫자로 치환하지 않는다.
    # B2 — legal_basis 의 §25①1호 오기.
    "private-contract-split-over-limit" => [
      [ "(총사업비 1억 5천만원)을 수의계약 한도액(5천만원)을 초과한다는 이유로",
        "(총사업비 1억 5천만원)을 수의계약 한도를 초과한다는 이유로" ],
      [ "총사업비는 **1억 5천만원**으로, 「지방계약법 시행령」 제25조의 용역 수의계약 한도액(5천만원)을 3배 초과하는 규모였습니다.",
        "총사업비는 **1억 5천만원**입니다. 수의계약이 가능한 한도는 「지방계약법 시행령」 제25조제1항제5호에 따라 " \
        "**계약유형(공사 / 물품·용역)과 상대방 요건(일반 업체·청년창업기업·소기업·소상공인 등)에 따라 달라지므로**, " \
        "이 사업이 어느 목에 해당하는지부터 확인해야 합니다. 이 사례에서 감사기관은 총사업비를 기준으로 경쟁입찰 대상이라고 판단하였습니다." ],
      [ "- **각 계약금액이 수의계약 한도(5천만원) 직하**", "- **각 계약금액이 5천만원 직하로 균일**" ],
      [ "전체 금액이 5천만원(용역·물품)을 초과하면 경쟁입찰 대상입니다. 분할한 각 계약이 5천만원 미만이더라도 분할 자체가 위법입니다.",
        "**전체 금액을 기준으로** 수의계약 한도(시행령 제25조제1항제5호 — 계약유형·상대방 요건에 따라 다름) 초과 여부를 " \
        "판단합니다. 분할한 각 계약이 한도 미만이더라도 분할 자체가 위법입니다." ],
      [ "총사업비가 수의계약 한도(5천만원)를 초과하는지 사업 전체 기준으로 판단",
        "총사업비가 수의계약 한도를 초과하는지 사업 전체 기준으로 판단 (한도는 시행령 제25조제1항제5호의 계약유형·상대방 요건에 따라 다름)" ],
      [ "지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 지방계약법 시행령 제77조",
        "지방계약법 시행령 #{HO5_LOCATOR}, 지방계약법 시행령 제77조" ]
    ].freeze,
    # F1 — 같은 오기를 가진 **다른 published 레코드**. 앞 라운드에서 «범위 밖» 으로 미뤘던 것.
    "quote-collection-same-vendor-double" => [
      [ "지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 행정안전부 예규 제2023-24호 제5장 제3절",
        "지방계약법 시행령 #{HO5_LOCATOR}, 행정안전부 예규 제2023-24호 제5장 제3절" ]
    ].freeze
  }.freeze

  AUDIT_FIELDS = %i[title issue detail legal_basis lesson action_taken checkpoints].freeze

  # ── Topic: slug → {필드 → 치환쌍} ────────────────────────────
  # F5 — 수의계약 한도 토픽의 법령 표제가 제1호(천재지변)로 적혀 있었다.
  TOPIC_SUBS = {
    "private-contract-limit" => {
      law_content: [
        [ "<strong>지방계약법 시행령 제25조 제1항 제1호 (수의계약 한도)</strong>",
          "<strong>지방계약법 시행령 제25조 제1항 제5호 (수의계약 한도)</strong>" ]
      ]
    }
  }.freeze

  # legal_basis 파생 verification_source 를 계약대로 다시 만든다.
  def self.expected_verification_source(legal_basis)
    budget = VS_MAX - VS_PREFIX.length - VS_SUFFIX.length
    lb = legal_basis.to_s.strip
    fit = lb.length > budget ? lb[0, budget - 1] + "…" : lb
    "#{VS_PREFIX}#{fit}#{VS_SUFFIX}"
  end

  # 파생 계약으로 만들어진 값만 대상. 사람이 쓴 설명이나 빈 값은 건드리지 않는다.
  def self.derived_verification_source?(value)
    value.to_s.start_with?(VS_PREFIX)
  end

  def self.substitute(raw, pairs)
    s = raw.is_a?(String) ? raw.dup : raw.to_json
    pairs.each { |old, new| s = s.gsub(old, new) if s.include?(old) }
    s
  end

  def self.apply!(dry_run: false)
    summary = { updated: 0, created: 0, missing: [], fields: [], vs_synced: [], already_ok: [] }

    AUDIT_SUBS.each do |slug, pairs|
      rec = AuditCase.find_by(slug: slug)          # ← create 하지 않는다
      if rec.nil?
        summary[:missing] << "AuditCase:#{slug}"
        next
      end
      dirty = false
      AUDIT_FIELDS.each do |f|
        next unless rec.has_attribute?(f.to_s)
        v = rec.read_attribute(f)
        next if v.blank?
        nv = substitute(v, pairs)
        next if nv == (v.is_a?(String) ? v : v.to_json)
        rec.write_attribute(f, v.is_a?(String) ? nv : JSON.parse(nv))
        dirty = true
        summary[:fields] << "AuditCase:#{slug}##{f}"
      end

      # F2 — legal_basis 가 바뀌면 파생 verification_source 도 같은 계약으로 다시 만든다.
      if rec.has_attribute?("verification_source") && derived_verification_source?(rec.verification_source)
        want = expected_verification_source(rec.legal_basis)
        if rec.verification_source != want
          rec.write_attribute(:verification_source, want)
          dirty = true
          summary[:vs_synced] << "AuditCase:#{slug}"
        end
      end

      if dirty
        rec.save! unless dry_run
        summary[:updated] += 1
      else
        summary[:already_ok] << "AuditCase:#{slug}"
      end
    end

    TOPIC_SUBS.each do |slug, fields|
      rec = Topic.find_by(slug: slug)              # ← create 하지 않는다
      if rec.nil?
        summary[:missing] << "Topic:#{slug}"
        next
      end
      dirty = false
      fields.each do |f, pairs|
        next unless rec.has_attribute?(f.to_s)
        v = rec.read_attribute(f)
        next if v.blank?
        nv = substitute(v, pairs)
        next if nv == (v.is_a?(String) ? v : v.to_json)
        rec.write_attribute(f, v.is_a?(String) ? nv : JSON.parse(nv))
        dirty = true
        summary[:fields] << "Topic:#{slug}##{f}"
      end
      if dirty
        rec.save! unless dry_run
        summary[:updated] += 1
      else
        summary[:already_ok] << "Topic:#{slug}"
      end
    end

    summary
  end
end unless defined?(SilmuDeployBlockerFix20260906)

# 자동 실행. 테스트는 `SILMU_SEED_AUTORUN=0` 으로 모듈만 로드한 뒤 apply! 를 직접 부른다 —
# load 가 곧바로 적용해 버리면 «기존 row 가 update 되는가» 를 재는 양성 대조가 무력해진다.
if ENV["SILMU_SEED_AUTORUN"] != "0"
  dry = ENV["SILMU_SEED_DRY_RUN"] == "1"
  s = SilmuDeployBlockerFix20260906.apply!(dry_run: dry)
  puts(dry ? "== DRY-RUN (DB 쓰기 0) ==" : "== APPLY ==")
  puts "ROWS_TO_UPDATE=#{s[:updated]}  CREATED=#{s[:created]}"
  puts "FIELDS(#{s[:fields].size}):"; s[:fields].each { |f| puts "  ✓ #{f}" }
  puts "VERIFICATION_SOURCE_SYNCED(#{s[:vs_synced].size}): #{s[:vs_synced].join(', ')}"
  puts "ALREADY_OK: #{s[:already_ok].join(', ')}" if s[:already_ok].any?
  puts "MISSING: #{s[:missing].join(', ')}" if s[:missing].any?
  puts "완료 — create 0 · R2 엔진·규칙집·임계값 변경 0"
end
