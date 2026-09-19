# frozen_string_literal: true

module ReviewLab
  # 입찰공고 패키지 검증기 V1 (요구서 §6·§7).
  #
  # 핵심은 문서 하나의 맞춤법이 아니라 **문서 간 일관성**이다.
  # 공고문·과업지시서·규격서가 같은 사업을 서로 다른 금액·기한·수량으로 적으면
  # 입찰 후 이의신청·재공고·계약 분쟁으로 번진다.
  #
  # 법규 검사는 원문을 확보한 것만 규칙으로 만든다(지방계약법 시행령 §35 — 입찰공고의 시기).
  # 업종·면허는 «후보» 까지만 말한다. 확정은 담당자 몫이다.
  class PackageReviewer
    F = FieldExtractor::PACKAGE_FIELDS

    # 상호대조 항목과 충돌 시 severity. 텍스트형 서술 항목(참가자격 등)은 행렬에만 보여주고 판정하지 않는다 —
    # 자유 서술을 기계로 «같다/다르다» 판정하면 거짓 충돌이 난다.
    COMPARE = {
      project_name: "WARN", notice_no: "BLOCK", estimated_price: "BLOCK", base_price: "BLOCK", budget: "BLOCK",
      quantity: "BLOCK", contract_period: "BLOCK", delivery_deadline: "BLOCK", announce_date: "BLOCK",
      bid_deadline: "BLOCK", opening: "BLOCK", contract_method: "WARN", award_method: "WARN"
    }.freeze
    MATRIX_ONLY = %i[qualification license region joint_contract bid_bond required_docs contact].freeze

    NOTICE_REQUIRED = {
      project_name: "사업명", price: "추정가격 또는 기초금액", bid_deadline: "입찰서 제출 마감",
      opening: "개찰일시", qualification: "입찰참가자격", contract_method: "계약방법",
      award_method: "낙찰자 결정방법", contact: "문의처"
    }.freeze

    CONTRACT_METHOD_WORDS = { "일반경쟁" => /일반\s*경쟁/, "제한경쟁" => /제한\s*경쟁/, "지명경쟁" => /지명\s*경쟁/,
                              "수의계약" => /수의\s*계약/, "협상에 의한 계약" => /협상에\s*의한/ }.freeze
    AWARD_METHOD_WORDS = { "적격심사" => /적격\s*심사/, "최저가" => /최저가/, "협상" => /협상/,
                           "종합심사" => /종합\s*심사/, "2단계" => /2\s*단계/ }.freeze

    # 과업 문구 → 업종·면허 **후보**. 조문 번호는 원문 대조 전이라 적지 않는다.
    LICENSE_HINTS = [
      { key: :electric, name: "전기공사업", law: "전기공사업법",
        pattern: /전기\s*(공사|배선|설비\s*공사)|배선\s*공사|분전반|콘센트\s*(증설|설치|신설)|전원\s*(공사|증설|배선)/,
        mention: /전기\s*공사업|전기공사/ },
      { key: :telecom, name: "정보통신공사업", law: "정보통신공사업법",
        pattern: /통신\s*(공사|배선)|네트워크\s*(배선|공사)|랜\s*(선|배선)\s*(공사|포설)?|UTP|광\s*케이블|CCTV\s*(설치|공사)|방송\s*설비\s*공사/,
        mention: /정보\s*통신\s*공사업|정보통신공사/ },
      { key: :fire, name: "소방시설공사업", law: "소방시설공사업법",
        pattern: /소방\s*(시설|설비)\s*(공사|설치)|스프링클러|화재\s*감지기\s*(설치|교체)|소화\s*설비\s*공사/,
        mention: /소방\s*시설\s*공사업|소방시설공사/ },
      { key: :building, name: "건설업(해당 업종)", law: "건설산업기본법",
        pattern: /철거\s*공사|방수\s*공사|도장\s*공사|미장\s*공사|창호\s*공사|실내\s*건축\s*공사|석면\s*해체/,
        mention: /건설업|실내건축|도장.*공사업|방수.*공사업|전문공사/ }
    ].freeze

    LOCAL_CONTRACT_SCOPES = %w[LOCAL_GOVERNMENT EDUCATION_OFFICE PUBLIC_SCHOOL].freeze

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(documents:, contract_type: nil, agency_scope: nil, today: Date.current)
      @documents = documents
      @contract_type = contract_type.to_s.presence
      @agency_scope = agency_scope.to_s.presence
      @today = today
    end

    def call
      @review = DocumentReview.new(kind: :package, documents: @documents)
      @docs = @review.readable_documents
      return @review if @docs.empty?

      @docs.each { |d| @review.fields[d.label] = expand_bid_period(FieldExtractor.extract(d, F)) }
      check_internal_consistency
      build_matrix
      check_notice_required
      check_date_order
      check_announcement_period
      check_price_relation
      check_license_candidates
      check_pii
      @review
    end

    private

    def rule_set = ContractDecision::RuleSet.current

    def add(**kw) = @review.add(Finding.new(**kw))

    def first(doc_label, key) = @review.fields.dig(doc_label, key)&.first

    def notice = @docs.find { |d| d.role == "notice" }

    # 공고문 값 우선, 없으면 문서 순서대로 첫 값.
    def pick(key)
      order = [ notice, *@docs ].compact.uniq
      order.each do |d|
        f = first(d.label, key)
        return f if f&.known?
      end
      nil
    end

    # «입찰서 제출기간: 2026. 10. 6. 10:00 ~ 2026. 10. 10. 18:00» → bid_start / bid_deadline
    def expand_bid_period(fields)
      period = fields[:bid_period]&.first
      if period
        parts = period.raw.to_s.split(/~|∼|부터/, 2)
        if parts.size == 2
          start = FieldExtractor.parse_datetime(parts[0])
          finish = FieldExtractor.parse_datetime(parts[1])
          fields[:bid_start] = [ period.dup.tap { |f| f.key = :bid_start; f.value = start; f.raw = parts[0].strip } ] if start
          if finish && fields[:bid_deadline].blank?
            fields[:bid_deadline] = [ period.dup.tap { |f| f.key = :bid_deadline; f.value = finish; f.raw = parts[1].strip } ]
          end
        end
      end
      fields
    end

    # ── 한 문서 안의 모순 ─────────────────────────────────────────────
    def check_internal_consistency
      evaluated = false
      @docs.each do |d|
        (COMPARE.keys - [ :quantity ]).each do |key|
          # 수량은 다품목 규격서에서 품목마다 다르게 적히는 것이 정상이라 문서 내부 모순으로 보지 않는다.
          vals = Array(@review.fields.dig(d.label, key)).select(&:known?)
          evaluated ||= vals.any?
          distinct = vals.uniq { |f| comparable(key, f.value) }
          next if distinct.size < 2 || incomparable_mix?(key, distinct)

          add(severity: COMPARE[key], code: "X-INTERNAL", source_document: d.label,
              location: distinct.map(&:locator).join(" / "), extracted_value: distinct.map(&:raw).join(" ↔ "),
              problem: "같은 문서 안에서 «#{F[key][0]}» 이 서로 다르게 적혀 있습니다",
              why_it_matters: "한 문서 안의 모순은 어느 값이 유효한지 다툼이 됩니다.",
              suggested_action: "하나로 통일하세요.")
        end
      end
      @review.rules_run += 1 if evaluated
    end

    # ── 문서 간 행렬 ─────────────────────────────────────────────────
    def build_matrix
      consistent = []
      (COMPARE.keys + MATRIX_ONLY).each do |key|
        cells = @docs.to_h { |d| [ d.label, first(d.label, key) ] }
        present = cells.compact.select { |_l, f| f.known? }
        next if cells.compact.empty?

        multi_docs = key == :quantity ? @docs.select { |d| Array(@review.fields.dig(d.label, key)).map { |f| comparable(key, f.value) }.uniq.size > 1 } : []
        multi_qty = multi_docs.any?
        multi_docs.each do |d|
          # 다품목이면 정상이고 단일 품목이면 모순이다 — 기계가 구별할 수 없으므로 침묵하지 않고 확인을 요청한다.
          vals = Array(@review.fields.dig(d.label, key))
          add(severity: "CHECK", code: "X-QTY-MULTI", source_document: d.label, location: vals.map(&:locator).join(" / "),
              extracted_value: vals.map(&:raw).join(" · "),
              problem: "한 문서에 수량이 여러 값으로 적혀 있습니다 — 품목별 수량인지, 같은 물품의 서로 다른 수량인지 확인하세요",
              suggested_action: "단일 품목이면 하나로 통일하세요.", confidence: "중간")
        end
        verdict = if MATRIX_ONLY.include?(key) || multi_qty then present.size >= 2 ? "원문 대조" : "단일"
        elsif present.size < 2 then "단일"
        else
          groups = present.values.group_by { |f| comparable(key, f.value) }
          if groups.size == 1
            consistent << F[key][0]
            "일치"
          elsif incomparable_mix?(key, present.values)
            "형식 다름"
          else
            report_conflict(key, present)
            "충돌"
          end
        end
        @review.comparisons << { key: key, name: F[key][0], cells: cells, verdict: verdict }
      end
      @review.rules_run += 1 if @review.comparisons.any? { |c| %w[일치 충돌 형식\ 다름].include?(c[:verdict]) }

      if consistent.any?
        add(severity: "PASS", code: "X-CONSISTENT", extracted_value: consistent.join(" · "),
            problem: "문서 간 일치 확인 #{consistent.size}개 항목: #{consistent.join(', ')}")
      end
      @review.comparisons.select { |c| c[:verdict] == "형식 다름" }.each do |c|
        add(severity: "CHECK", code: "X-FORMAT", extracted_value: c[:cells].compact.map { |l, f| "#{l}: #{f.raw}" }.join(" / "),
            problem: "«#{c[:name]}» 을 문서마다 다른 형식(일수·날짜 범위)으로 적어 기계로 비교할 수 없습니다",
            suggested_action: "같은 기준(예: «계약일로부터 30일»)으로 통일하세요.")
      end
    end

    def report_conflict(key, present)
      # 위치에 문서명이 이미 들어 있으므로 source_document 를 따로 적지 않는다(화면에서 문서명이 두 번 나온다).
      add(severity: COMPARE.fetch(key), code: "X-CONFLICT",
          location: present.map { |l, f| "#{l} #{f.locator}" }.join(" / "),
          extracted_value: present.map { |l, f| "#{l}: #{f.raw}" }.join(" ↔ "),
          problem: "«#{F[key][0]}» 이 문서마다 다릅니다",
          why_it_matters: conflict_why(key),
          evidence: [ "상호대조: 같은 항목의 문서별 값 비교" ],
          suggested_action: "공고 전에 한 값으로 맞추고, 이미 공고했다면 정정공고 여부를 검토하세요.")
    end

    def conflict_why(key)
      case key
      when :estimated_price, :base_price, :budget then "금액이 다르면 예정가격·입찰 참가 판단이 문서마다 달라집니다."
      when :quantity then "수량이 다르면 납품·검수 기준이 둘이 됩니다."
      when :contract_period, :delivery_deadline then "기한이 다르면 지체상금 기산일을 두고 분쟁이 납니다."
      when :bid_deadline, :opening, :announce_date then "입찰 일정이 다르면 입찰 참가 기회가 달라져 이의신청 사유가 됩니다."
      else "문서 간 불일치는 입찰 참가자가 어느 문서를 따를지 알 수 없게 만듭니다."
      end
    end

    # 비교 가능한 형태로 정규화.
    def comparable(key, v)
      case v
      when Hash
        if v.key?(:qty) then v[:qty]
        elsif v.key?(:days) then [ :days, v[:days] ]
        elsif v.key?(:from) then [ :range, v[:from], v[:to] ]
        elsif v.key?(:until) then [ :until, v[:until] ]
        elsif v.key?(:date) then [ v[:date], v[:time] ]
        else v
        end
      when String
        case key
        when :contract_method then CONTRACT_METHOD_WORDS.find { |_n, re| v.match?(re) }&.first || v.gsub(/\s/, "")
        when :award_method then AWARD_METHOD_WORDS.find { |_n, re| v.match?(re) }&.first || v.gsub(/\s/, "")
        else v.gsub(/[\s·,()\[\]「」『』"'“”]/, "")
        end
      else v
      end
    end

    # 일수와 날짜 범위가 섞여 있으면 기산일을 모르므로 비교하지 않는다.
    # 시각이 한쪽에만 있는 일시도 날짜가 같으면 «충돌» 이 아니라 «형식 다름» 이다.
    def incomparable_mix?(key, fields)
      vals = fields.map(&:value)
      if %i[contract_period delivery_deadline].include?(key)
        return vals.map { |v| v.is_a?(Hash) ? v.keys.first : nil }.uniq.size > 1
      end
      if %i[bid_deadline opening].include?(key)
        dates = vals.map { |v| v[:date] }.uniq
        return dates.size == 1 && vals.map { |v| v[:time] }.compact.uniq.size <= 1
      end
      false
    end

    # ── 공고문 필수 항목 ─────────────────────────────────────────────
    def check_notice_required
      unless notice
        @review.skip("X-MISSING", "공고문 역할로 올린 문서가 없습니다")
        return
      end
      @review.rules_run += 1
      NOTICE_REQUIRED.each do |key, name|
        present = if key == :price
          first(notice.label, :estimated_price) || first(notice.label, :base_price)
        else
          first(notice.label, key)
        end
        next if present

        add(severity: "WARN", code: "X-MISSING", source_document: notice.label, problem: "공고문에서 «#{name}» 을 찾지 못했습니다",
            why_it_matters: "입찰 참가자가 판단에 필요한 정보를 공고문에서 확인할 수 없습니다.",
            suggested_action: "«#{name}: …» 형식의 항목이 공고문에 있는지 원문을 확인하세요(표기가 달라 못 찾았을 수도 있습니다).",
            confidence: "중간 — 라벨 표기가 다르면 못 찾을 수 있음")
      end
    end

    # ── 일정 순서 ───────────────────────────────────────────────────
    def check_date_order
      ann = pick(:announce_date)&.value
      start = pick(:bid_start)&.value
      deadline = pick(:bid_deadline)&.value
      opening = pick(:opening)&.value
      points = [ [ "공고일", ann && { date: ann, time: nil } ], [ "입찰서 제출 개시", start ], [ "입찰서 제출 마감", deadline ], [ "개찰", opening ] ]
               .select { |_n, d| d }
      if points.size < 2
        @review.skip("P-ORDER", "공고일·제출기간·개찰일 중 2개 이상을 찾지 못했습니다")
        return
      end
      @review.rules_run += 1
      bad = points.each_cons(2).select { |(_, a), (_, b)| before?(b, a) }
      if bad.any?
        bad.each do |(na, a), (nb, b)|
          add(severity: "BLOCK", code: "P-ORDER", extracted_value: "#{na} #{when_text(a)} → #{nb} #{when_text(b)}",
              problem: "#{nb}(#{when_text(b)})이 #{na}(#{when_text(a)})보다 앞섭니다", why_it_matters: "입찰 일정이 성립하지 않습니다.",
              suggested_action: "일정을 바로잡으세요.")
        end
      else
        add(severity: "PASS", code: "P-ORDER", extracted_value: points.map { |n, d| "#{n} #{when_text(d)}" }.join(" → "),
            problem: "입찰 일정 순서가 맞습니다")
      end
    end

    # 날짜가 같으면 둘 다 시각이 있을 때만 시각으로 비교한다(한쪽 시각 미상은 순서를 판정하지 않는다).
    def before?(b, a)
      return b[:date] < a[:date] if b[:date] != a[:date]
      return false unless b[:time] && a[:time]

      b[:time] < a[:time]
    end

    def when_text(v) = [ v[:date], v[:time] ].compact.join(" ")

    # ── 지방계약법 시행령 §35 공고기간 ────────────────────────────────
    def check_announcement_period
      ann_f = pick(:announce_date)
      dl_f = pick(:bid_deadline)
      unless ann_f && dl_f
        @review.skip("P-35", "공고일 또는 입찰서 제출 마감일을 찾지 못했습니다")
        return
      end
      @review.rules_run += 1

      if @agency_scope && !LOCAL_CONTRACT_SCOPES.include?(@agency_scope)
        add(severity: "CHECK", code: "P-35", problem: "공고기간 규칙은 지방계약법 기준입니다 — 선택한 기관 범위에는 다른 법령이 적용됩니다",
            why_it_matters: "사립학교·국가기관·공공기관은 각자의 계약 법령·규정을 따릅니다.",
            suggested_action: "기관에 적용되는 계약 규정의 공고기간을 확인하세요.")
        return
      end

      announce = ann_f.value
      deadline = dl_f.value[:date]
      gap = (deadline - announce).to_i
      required, clause, basis_note, certain = required_days
      citation = rule_set.citation("LOCAL_CONTRACT_DECREE", clause,
                                   quote: "입찰공고는 그 입찰서 제출 마감일의 전날부터 기산하여 7일 전에 하여야 한다.")
      value = "공고일 #{announce} · 마감 #{deadline} · 간격 #{gap}일 · 기준 #{required}일(#{basis_note})"

      if !certain && gap > required && gap <= MAX_REQUIRED_DAYS
        # 기준 일수가 계약유형·추정가격에 달려 있는데 그 값을 모른다 — 최소값을 넘었다고 PASS 로 올리지 않는다.
        add(severity: "CHECK", code: "P-35", extracted_value: value, evidence: [ citation ],
            problem: "공고기간 기준을 확정하지 못했습니다 (#{basis_note})",
            why_it_matters: "공사는 추정가격 구간에 따라 7·15·30·40일, 협상에 의한 계약은 10·20·40일이 기준입니다.",
            suggested_action: "계약 유형을 고르고 공고문에 추정가격이 적혀 있는지 확인하세요.", confidence: "중간 — 기준 미확정")
      elsif gap > required
        add(severity: "PASS", code: "P-35", extracted_value: value, evidence: [ citation ],
            problem: "공고기간이 기준(#{required}일)을 충족합니다")
      elsif gap == required
        add(severity: "CHECK", code: "P-35", extracted_value: value, evidence: [ citation ],
            problem: "공고기간이 기준일수와 정확히 같은 경계입니다",
            why_it_matters: "«마감일의 전날부터 기산하여 #{required}일 전» 의 역산 방식에 따라 하루 차이로 충족·미달이 갈립니다.",
            suggested_action: "하루 앞당겨 공고하거나, 기관의 기간 계산 기준으로 확인하세요.", confidence: "중간 — 경계 해석")
      else
        add(severity: "WARN", code: "P-35", source_document: [ ann_f.document, dl_f.document ].uniq.join(" · "),
            location: "#{ann_f.locator} / #{dl_f.locator}", extracted_value: value, evidence: [ citation ],
            problem: "공고기간이 기준보다 짧습니다 (#{gap}일 < #{required}일)",
            why_it_matters: "시행령 §35④ 의 긴급 사유(재공고·조기집행·긴급 행사·재해 등, 5일)나 §35⑥(협상 등, 10일)에 해당하지 않으면 공고기간 미달입니다.",
            suggested_action: "긴급공고 사유가 있으면 공고문에 그 사유를 적고, 없으면 마감일을 늦추세요.")
      end

      if construction? && site_briefing_mentioned?
        add(severity: "CHECK", code: "P-35", problem: "공사 입찰에 현장설명이 언급돼 있습니다 — 공고기간은 현장설명일 기준으로도 확인하세요",
            evidence: [ rule_set.citation("LOCAL_CONTRACT_DECREE", "제35조제2항") ],
            suggested_action: "현장설명일 전날부터 기산한 기간을 따로 확인하세요.")
      end
    end

    MAX_REQUIRED_DAYS = 40

    # => [기준 일수, 조문, 설명, 확정 여부]
    # 확정 여부 = 기준을 정하는 데 필요한 값(계약유형·추정가격)을 모두 알았는가.
    def required_days
      price = pick(:estimated_price)&.value
      if negotiation?
        return [ 10, "제35조제5항", "협상에 의한 계약 · 추정가격 미확인 — 최소값", false ] unless price

        days = price < 100_000_000 ? 10 : price < 1_000_000_000 ? 20 : 40
        return [ days, "제35조제5항", "협상에 의한 계약 · 추정가격 #{price.to_fs(:delimited)}원", true ]
      end
      if @contract_type.nil?
        return [ 7, "제35조제1항", "계약 유형 미선택 — 공사라면 추정가격에 따라 더 길 수 있음", false ]
      end
      if construction? && !site_briefing_mentioned?
        return [ 7, "제35조제3항", "공사 · 추정가격 미확인 — 최소값", false ] unless price

        days = price < 1_000_000_000 ? 7 : price < 5_000_000_000 ? 15 : 30
        return [ days, "제35조제3항", "공사(현장설명 없음) · 추정가격 #{price.to_fs(:delimited)}원#{price >= 5_000_000_000 ? ' · 고시금액 이상이면 40일' : ''}",
                 price < 5_000_000_000 ]
      end
      [ 7, "제35조제1항", construction? ? "공사(현장설명 있음) — 마감일 기준 최소값" : "물품·용역 기본", true ]
    end

    def construction? = @contract_type.to_s.start_with?("construction")

    # 공고문·과업지시서 어디든 계약방법·낙찰방법에 «협상» 이 적혀 있으면 협상 기준(§35⑤)을 쓴다 — 긴 쪽 기준이 보수적이다.
    def negotiation?
      @docs.any? do |d|
        [ :contract_method, :award_method ].any? { |k| Array(@review.fields.dig(d.label, k)).any? { |f| f.value.to_s.match?(/협상/) } }
      end
    end

    def site_briefing_mentioned?
      @docs.any? { |d| @review.fields.dig(d.label, :site_briefing).present? }
    end

    # ── 기초금액·추정가격 관계 ───────────────────────────────────────
    def check_price_relation
      est = pick(:estimated_price)&.value
      base = pick(:base_price)&.value
      unless est && base
        @review.skip("P-PRICE", "추정가격과 기초금액을 둘 다 찾지 못했습니다")
        return
      end
      @review.rules_run += 1
      ratio = base.to_f / est
      value = "기초금액 #{base.to_fs(:delimited)}원 ÷ 추정가격 #{est.to_fs(:delimited)}원 = #{ratio.round(3)}"
      if ratio.between?(1.09, 1.11)
        add(severity: "PASS", code: "P-PRICE", extracted_value: value, problem: "기초금액이 추정가격에 부가세 10%를 더한 수준입니다",
            evidence: [ rule_set.citation("LOCAL_CONTRACT_DECREE", "제7조", quote: nil) ])
      else
        add(severity: "CHECK", code: "P-PRICE", extracted_value: value,
            problem: "기초금액과 추정가격의 관계가 «추정가격 + 부가세 10%» 와 다릅니다",
            why_it_matters: "추정가격은 부가세를 뺀 금액입니다. 관급자재·면세·오기 여부에 따라 정상일 수도, 오류일 수도 있습니다.",
            evidence: [ rule_set.citation("LOCAL_CONTRACT_DECREE", "제7조") ],
            suggested_action: "산출 내역으로 차이를 설명할 수 있는지 확인하세요.")
      end
    end

    # ── 업종·면허 후보 ───────────────────────────────────────────────
    # 후보 탐지는 보조 검사라 «실행한 규칙» 수에 넣지 않는다 — 넣으면 라벨을 하나도 못 읽은 묶음도
    # «규칙 N개에서 문제 없음» 으로 보인다(정확성 리뷰 #14).
    def check_license_candidates
      qual_text = [ :qualification, :license ].flat_map { |k| @docs.flat_map { |d| Array(@review.fields.dig(d.label, k)).map(&:raw) } }.join(" ")
      candidates = []
      LICENSE_HINTS.each do |hint|
        hit = @docs.lazy.flat_map { |d| d.segments.map { |s| [ d, s ] } }.find { |_d, s| s[:text].match?(hint[:pattern]) }
        next unless hit

        doc, seg = hit
        candidates << hint[:name]
        law = law_ref(hint[:law])
        if qual_text.match?(hint[:mention])
          add(severity: "PASS", code: "L-LICENSE", source_document: doc.label, location: seg[:locator],
              extracted_value: seg[:text].truncate(80), problem: "과업에 #{hint[:name]} 관련 작업이 있고, 참가자격에 해당 업종 표기가 있습니다",
              evidence: [ law ], confidence: "중간 — 키워드 기준")
        else
          add(severity: "CHECK", code: "L-LICENSE", source_document: doc.label, location: seg[:locator],
              extracted_value: seg[:text].truncate(80),
              problem: "후보 업종: #{hint[:name]} — 과업에 관련 작업이 있는데 참가자격에서 해당 업종을 찾지 못했습니다",
              why_it_matters: "해당 작업을 무자격 업체가 하면 계약·준공 단계에서 문제가 됩니다. 단, 작업 규모·성격에 따라 등록이 필요 없는 경우도 있습니다.",
              evidence: [ law ],
              suggested_action: "업종·면허 필요 여부는 담당자가 해당 법령과 교육청 지침으로 확정하세요. 이 결과는 후보입니다.",
              confidence: "중간 — 키워드 기준 후보")
        end
      end
      return if candidates.none? { |c| c.match?(/전기|정보통신|소방/) }

      add(severity: "CHECK", code: "L-SPLIT", extracted_value: candidates.join(" · "),
          problem: "전기·정보통신·소방 공사는 다른 공사·물품과 분리해 발주하는 것이 원칙인 법률이 있습니다",
          why_it_matters: "물품 구매에 공사를 섞어 발주하면 분리발주 원칙 위반 여부가 문제될 수 있습니다(예외 규정 있음).",
          evidence: [ law_ref("전기공사업법"), law_ref("정보통신공사업법"), law_ref("소방시설공사업법") ],
          suggested_action: "분리발주 대상인지, 예외에 해당하는지 담당자가 법령 원문으로 확인하세요.",
          confidence: "중간 — 조문 번호 미표기(원문 확인 필요)")
    end

    def law_ref(name)
      url = LegalReferenceResolver::KNOWN_LAWS.key?(name) ? LegalReferenceResolver.official_url_for(LegalReferenceResolver::KNOWN_LAWS[name]) : nil
      { title: name, short: name, locator: nil, url: url }
    end

    def check_pii
      @docs.each do |d|
        hits = PiiScanner.scan(d)
        next if hits.empty?

        add(severity: "CHECK", code: "PII", source_document: d.label, location: hits.map { |h| h[:locator] }.uniq.first(5).join(", "),
            extracted_value: hits.map { |h| h[:label] }.uniq.join(" · "),
            problem: "개인정보로 보이는 값이 #{hits.size}곳 있습니다(값은 표시하지 않습니다)",
            why_it_matters: "공고문은 공개 문서입니다. 담당자 개인 휴대전화·이메일 등이 그대로 공개될 수 있습니다.",
            suggested_action: "공개용에는 기관 대표번호를 쓰세요.")
      end
    end
  end
end
