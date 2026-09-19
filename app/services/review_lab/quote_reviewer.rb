# frozen_string_literal: true

module ReviewLab
  # 견적서 검증기 V1 (요구서 §5).
  #
  # 순서 = 구조화 → 규칙 검사 → 기존 계약 판정기 연결 → 가격 근거 수준.
  #   · 산술(행 금액·공급가액·부가세·합계)은 코드가 한다. AI 에게 맡기지 않는다.
  #   · 가격이 «비싸다/적정하다» 는 판정하지 않는다. 판정하는 것은 **가격 근거가 얼마나 있는가** 뿐이다.
  #   · 값이 AI 로 읽힌 경우(이미지 견적서) 산술 결과도 확정(BLOCK)이 아니라 확인(CHECK)이다 —
  #     AI 가 숫자를 잘못 읽었을 가능성을 배제할 수 없다.
  class QuoteReviewer
    VAT_RATE = Rational(1, 10)
    VAT_TOLERANCE = 10 # 원 — 원 단위 절사 관행
    BUSINESS_NO = /\A\d{3}-\d{2}-\d{5}\z/
    CONTRACT_TYPES = %w[goods service construction_general construction_special construction_etc].freeze

    PRICE_LEVELS = {
      "PRICE_EVIDENCE_STRONG"       => "모든 품목에 같은 규격의 비교견적이 있습니다",
      "PRICE_EVIDENCE_PARTIAL"      => "일부 품목만 같은 규격의 비교견적이 있습니다",
      "PRICE_EVIDENCE_INSUFFICIENT" => "비교견적이 없습니다(견적서 1부)",
      "NOT_COMPARABLE"              => "비교견적은 있으나 규격이 달라 가격을 비교할 수 없습니다"
    }.freeze

    def self.call(**kwargs) = new(**kwargs).call

    # documents: [주 견적서, 비교견적…] (DocumentArtifact)
    # ai_fields: 주 견적서를 AI 로 읽은 결과(DocumentAnalyzerService quote_extraction 의 fields) — 선택
    def initialize(documents:, contract_type: nil, agency_scope: nil, counterparty_type: nil, today: Date.current, ai_fields: nil)
      @documents = documents
      @contract_type = CONTRACT_TYPES.include?(contract_type.to_s) ? contract_type.to_s : nil
      @agency_scope = agency_scope.presence
      @counterparty_type = counterparty_type.presence
      @today = today
      @ai_fields = ai_fields
    end

    def call
      @review = DocumentReview.new(kind: :quote, documents: @documents)
      main = @documents.first
      return @review unless main

      load_main(main)
      return @review if @items.nil? # 읽지도, AI 값도 없음 → inconclusive

      check_items
      check_amounts
      check_vendor_and_dates
      check_pii
      link_contract_decision
      assess_price_evidence
      @review
    end

    private

    # ── 구조화 ───────────────────────────────────────────────────────
    def load_main(main)
      if main.ok?
        fields = FieldExtractor.extract(main, FieldExtractor::QUOTE_FIELDS)
        @review.fields[main.label] = fields
        # 같은 항목을 여러 라벨이 잡으면 더 구체적인 라벨(사전 순서가 앞선 것)을 쓴다 —
        # 품목표의 «합계»(부가세 전 소계)가 «합계금액» 을 덮으면 합계 검산이 거짓 오류를 낸다.
        @values = fields.to_h do |key, list|
          labels = FieldExtractor::QUOTE_FIELDS.dig(key, 2) || []
          [ key, list.each_with_index.min_by { |f, i| [ labels.index(f.label) || labels.size, i ] }&.first ]
        end
        @items = ItemTable.parse(main)
        @from_ai = false
      elsif @ai_fields.present?
        @values, @items = from_ai_fields(main)
        @from_ai = true
      end
      @main = main
    end

    def from_ai_fields(main)
      f = @ai_fields.stringify_keys
      mk = ->(key, value, raw = value) { value.nil? ? nil : ExtractedField.new(key: key, value: value, raw: raw.to_s, document: main.label, locator: "AI 판독", origin: :ai) }
      values = {
        company_name: mk.(:company_name, f["company_name"]), business_no: mk.(:business_no, f["business_no"]),
        representative: mk.(:representative, f["representative"]),
        quote_date: mk.(:quote_date, FieldExtractor.parse_date(f["quote_date"]), f["quote_date"]),
        validity: mk.(:validity, FieldExtractor.parse_days(f["validity_period"]), f["validity_period"]),
        delivery_deadline: mk.(:delivery_deadline, FieldExtractor.parse_days(f["delivery_period"]) || f["delivery_period"].presence, f["delivery_period"]),
        payment_terms: mk.(:payment_terms, f["payment_terms"].presence),
        supply_amount: mk.(:supply_amount, int_or_nil(f["supply_amount"])), vat_amount: mk.(:vat_amount, int_or_nil(f["vat_amount"])),
        total_amount: mk.(:total_amount, int_or_nil(f["total_amount"]))
      }.compact
      items = Array(f["items"]).map do |it|
        qty = int_or_nil(it["qty"])
        price = int_or_nil(it["unit_price"])
        # 기존 추출 프롬프트는 행 금액을 받지 않는다 → 행 산술은 검사할 수 없다(amount=nil, 곱을 지어내지 않는다).
        ItemTable::Item.new(name: it["name"].presence, spec: it["spec"].presence, unit: it["unit"].presence,
                            qty: qty, unit_price: price, amount: nil, locator: "AI 판독", confidence: "낮음 — AI가 읽은 값(원문 대조 필수)")
      end
      @review.fields[main.label] = values.transform_values { |v| [ v ] }
      [ values, items ]
    end

    def int_or_nil(v)
      return nil if v.nil?
      return (v.to_f.finite? ? v.round : nil) if v.is_a?(Numeric)

      str = v.to_s.strip
      return str.to_f.round if str.match?(/\A\d+(?:\.0+)?\z/)   # AI 가 «45000000.0» 처럼 문자열로 준 정수

      FieldExtractor.parse_amount(str)
    end

    def value(key) = @values[key]&.value
    def field(key) = @values[key]

    # AI 로 읽은 값에서 나온 결론은 확정하지 않는다.
    def sev(severity) = @from_ai ? "CHECK" : severity

    def add(severity:, code:, **rest)
      rest[:problem] = "(AI가 읽은 값 기준) #{rest[:problem]}" if @from_ai
      rest[:confidence] ||= @from_ai ? "낮음 — AI 판독값" : "높음"
      @review.add(Finding.new(severity: sev(severity), code: code, source_document: @main.label, **rest))
    end

    def won(n) = n.nil? ? "—" : "#{n.to_i.to_fs(:delimited)}원"

    # ── 품목 ─────────────────────────────────────────────────────────
    def check_items
      if @items.empty?
        @review.skip("Q-ROW", "품목표(품명·수량·단가 머리행)를 찾지 못했습니다")
        add(severity: "CHECK", code: "Q-ITEMS-READ", problem: "품목표를 읽지 못했습니다",
            why_it_matters: "품목별 산술·규격·단위 검사를 할 수 없습니다. 검사하지 못한 것을 «문제 없음» 으로 보면 안 됩니다.",
            suggested_action: "머리행에 «품명·규격·단위·수량·단가·금액» 이 있는 원본(XLSX·HWPX·DOCX)으로 올려 보세요.")
        return
      end

      row_errors = []
      checked = 0
      @items.each_with_index do |it, i|
        next if it.qty.nil? || it.unit_price.nil? || it.amount.nil?

        checked += 1
        expected = it.qty * it.unit_price
        row_errors << [ i, it, expected ] if (expected - it.amount).abs >= 1
      end
      @review.rules_run += 1 if checked.positive?
      @review.skip("Q-ROW", "행 금액이 없어 수량×단가를 대조하지 못했습니다") if checked.zero?

      row_errors.each do |i, it, expected|
        add(severity: "BLOCK", code: "Q-ROW", location: it.locator,
            extracted_value: "#{it.name}: 수량 #{it.qty} × 단가 #{won(it.unit_price)} ≠ 금액 #{won(it.amount)}",
            problem: "#{i + 1}번째 품목의 금액이 수량×단가와 다릅니다 (계산값 #{won(expected)}, 차이 #{won(it.amount - expected)})",
            why_it_matters: "행 금액이 틀리면 공급가액·부가세·합계와 예정가격 조서가 모두 틀어집니다.",
            evidence: [ "산술 검사: 수량 × 단가 = 금액" ],
            suggested_action: "업체에 정정 견적서를 요청하세요. 임의로 고쳐 쓰지 않습니다.", confidence: it.confidence)
      end
      if checked.positive? && row_errors.empty?
        add(severity: "PASS", code: "Q-ROW", extracted_value: "#{checked}개 품목",
            problem: "품목 #{checked}개 모두 수량×단가 = 금액", evidence: [ "산술 검사" ])
      end

      check_item_hygiene
    end

    def check_item_hygiene
      @review.rules_run += 1
      @items.group_by { |it| [ it.name.to_s.delete(" "), it.spec.to_s.delete(" ") ] }.each do |(name, _spec), group|
        next if name.empty? || group.size < 2

        add(severity: "WARN", code: "Q-DUP", location: group.map(&:locator).join(", "), extracted_value: group.first.name,
            problem: "같은 품명·규격이 #{group.size}번 나옵니다",
            why_it_matters: "중복 기재면 금액이 이중으로 잡힙니다. 의도한 분할이면 구분 표시가 필요합니다.",
            suggested_action: "중복인지 업체에 확인하세요.")
      end
      @items.each do |it|
        if it.spec.blank?
          add(severity: "WARN", code: "Q-SPEC", location: it.locator, extracted_value: it.name,
              problem: "«#{it.name}» 의 규격이 비어 있습니다",
              why_it_matters: "규격이 없으면 납품 검수 기준이 없고, 다른 견적과 같은 물건인지 비교할 수 없습니다.",
              suggested_action: "모델명·치수·사양을 적은 견적서를 받으세요.")
        end
        next if it.unit.present?

        add(severity: "WARN", code: "Q-UNIT", location: it.locator, extracted_value: it.name,
            problem: "«#{it.name}» 의 단위가 비어 있습니다",
            why_it_matters: "단위가 없으면 수량의 의미(개·세트·식)가 확정되지 않습니다.",
            suggested_action: "단위를 적어 달라고 요청하세요.")
      end
    end

    # ── 금액 ─────────────────────────────────────────────────────────
    def check_amounts
      supply = value(:supply_amount)
      vat = value(:vat_amount)
      total = value(:total_amount)
      rows = @items.map(&:amount)

      if supply && rows.any? && rows.none?(&:nil?)
        @review.rules_run += 1
        sum = rows.sum
        if sum != supply
          construction = @contract_type.to_s.start_with?("construction")
          add(severity: construction ? "CHECK" : "BLOCK", code: "Q-SUPPLY", location: field(:supply_amount)&.locator,
              extracted_value: "공급가액 #{won(supply)} / 품목 금액 합 #{won(sum)}",
              problem: "공급가액이 품목 금액의 합과 다릅니다 (차이 #{won(supply - sum)})",
              why_it_matters: construction ? "공사 견적은 간접공사비(일반관리비·이윤 등)가 품목 밖에 있어 차이가 날 수 있습니다. 간접비 내역으로 차이를 설명할 수 있는지 확인하세요." : "공급가액이 품목 합과 다르면 어느 쪽이 맞는지 알 수 없습니다.",
              evidence: [ "산술 검사: Σ 품목 금액 = 공급가액" ],
              suggested_action: "차이 금액의 내역(운반비·설치비 등)이 견적서에 있는지 확인하고, 없으면 정정 견적을 받으세요.")
        else
          add(severity: "PASS", code: "Q-SUPPLY", extracted_value: won(supply), problem: "공급가액 = 품목 금액의 합")
        end
      else
        @review.skip("Q-SUPPLY", supply ? "품목 금액을 모두 읽지 못했습니다" : "공급가액을 찾지 못했습니다")
      end

      if supply && vat
        @review.rules_run += 1
        expected = (supply * VAT_RATE).floor
        if vat.zero?
          add(severity: "CHECK", code: "Q-VAT", location: field(:vat_amount)&.locator, extracted_value: won(vat),
              problem: "부가세가 0원입니다", why_it_matters: "면세 품목(도서 등)이면 정상이지만, 과세 품목이면 누락입니다.",
              evidence: [ "부가가치세법 — 면세 대상 여부 확인" ], suggested_action: "면세 품목인지 확인하세요.")
        elsif (vat - expected).abs <= VAT_TOLERANCE
          add(severity: "PASS", code: "Q-VAT", extracted_value: won(vat), problem: "부가세 = 공급가액의 10%")
        else
          add(severity: "WARN", code: "Q-VAT", location: field(:vat_amount)&.locator,
              extracted_value: "부가세 #{won(vat)} / 공급가액×10% = #{won(expected)}",
              problem: "부가세가 공급가액의 10%와 다릅니다 (차이 #{won(vat - expected)})",
              why_it_matters: "과세·면세 품목이 섞였으면 정상일 수 있지만, 아니라면 금액 오류입니다.",
              evidence: [ "부가가치세법 — 세율 10%" ],
              suggested_action: "면세 품목이 섞였는지 확인하고, 아니면 정정 견적을 받으세요.")
        end
      else
        @review.skip("Q-VAT", "공급가액 또는 부가세를 찾지 못했습니다")
      end

      if supply && vat && total
        @review.rules_run += 1
        if total == supply && vat.positive?
          add(severity: "CHECK", code: "Q-TOTAL", location: field(:total_amount)&.locator, extracted_value: won(total),
              problem: "«합계» 로 읽은 값이 공급가액과 같습니다 — 부가세 포함 합계가 아니라 소계일 수 있습니다",
              suggested_action: "견적서의 최종 합계(부가세 포함) 칸을 원문에서 확인하세요.", confidence: "중간")
        elsif supply + vat == total
          add(severity: "PASS", code: "Q-TOTAL", extracted_value: won(total), problem: "합계 = 공급가액 + 부가세")
        else
          add(severity: "BLOCK", code: "Q-TOTAL", location: field(:total_amount)&.locator,
              extracted_value: "합계 #{won(total)} / 공급가액+부가세 = #{won(supply + vat)}",
              problem: "합계금액이 공급가액+부가세와 다릅니다", why_it_matters: "계약금액이 어느 값인지 확정되지 않습니다.",
              evidence: [ "산술 검사: 공급가액 + 부가세 = 합계" ], suggested_action: "정정 견적을 받으세요.")
        end
      else
        @review.skip("Q-TOTAL", "공급가액·부가세·합계 중 하나 이상을 찾지 못했습니다")
      end
    end

    # ── 업체·날짜·납품 ───────────────────────────────────────────────
    def check_vendor_and_dates
      @review.rules_run += 1
      missing(:company_name, "업체명(상호)", "견적 주체가 확인되지 않으면 견적서로 쓸 수 없습니다.")
      if (bn = value(:business_no))
        unless bn.to_s.strip.match?(BUSINESS_NO)
          add(severity: "WARN", code: "Q-VENDOR", location: field(:business_no).locator, extracted_value: bn,
              problem: "사업자등록번호 형식(000-00-00000)이 아닙니다", why_it_matters: "업체 확인(휴·폐업 조회)을 할 수 없습니다.",
              suggested_action: "사업자등록증과 대조하세요.")
        end
      else
        missing(:business_no, "사업자등록번호", "업체 휴·폐업 여부와 자격을 확인할 수 없습니다.")
      end

      qd = value(:quote_date)
      if qd.nil?
        missing(:quote_date, "견적일", "견적 시점을 알 수 없어 유효기간을 판단할 수 없습니다.")
      elsif qd > @today
        add(severity: "CHECK", code: "Q-DATE", location: field(:quote_date).locator, extracted_value: qd.to_s,
            problem: "견적일이 오늘보다 뒤입니다", suggested_action: "견적일 오기인지 확인하세요.")
      end

      validity = value(:validity)
      if validity.nil?
        missing(:validity, "유효기간", "견적 가격이 언제까지 유효한지 알 수 없습니다.")
      elsif (end_date = validity_end(qd, validity))
        if end_date < @today
          add(severity: "WARN", code: "Q-VALID", location: field(:validity).locator, extracted_value: field(:validity).raw,
              problem: "견적 유효기간이 지났습니다 (#{end_date} 만료)", why_it_matters: "만료된 견적 가격으로 계약할 수 없습니다.",
              suggested_action: "재견적을 받으세요.")
        else
          add(severity: "PASS", code: "Q-VALID", extracted_value: "#{end_date}까지", problem: "견적 유효기간 안입니다")
        end
      else
        add(severity: "CHECK", code: "Q-VALID", location: field(:validity).locator, extracted_value: field(:validity).raw,
            problem: "유효기간의 만료일을 계산하지 못했습니다", suggested_action: "기산일을 확인하세요.")
      end

      missing(:delivery_deadline, "납품기한", "납품기한이 없으면 지체상금을 물을 기준일이 없습니다.")
      unless value(:delivery_terms)
        add(severity: "CHECK", code: "Q-DELIVERY-TERMS", problem: "납품조건(장소·설치 포함 여부)이 적혀 있지 않습니다",
            why_it_matters: "설치·운반비 포함 여부에 따라 같은 금액도 비교 조건이 달라집니다.",
            suggested_action: "설치·운반 포함 여부를 확인하세요.")
      end
    end

    def validity_end(quote_date, validity)
      return validity[:until] if validity[:until]
      return validity[:to] if validity[:to]
      return nil unless validity[:days] && quote_date
      # 기산일이 견적일이 아니면(«발주일로부터 30일») 만료일을 계산할 수 없다 → CHECK 로 넘긴다.
      return nil if validity[:base].present? && validity[:base] != "견적일"

      quote_date + validity[:days]
    end

    MISSING_CODES = { company_name: "Q-VENDOR", business_no: "Q-VENDOR", quote_date: "Q-DATE",
                      validity: "Q-VALID", delivery_deadline: "Q-DELIVERY" }.freeze

    def missing(key, name, why)
      return if value(key)

      add(severity: "WARN", code: MISSING_CODES.fetch(key), problem: "«#{name}» 항목을 찾지 못했습니다", why_it_matters: why,
          suggested_action: "«#{name}» 이 적힌 견적서를 받으세요(표기가 달라 못 찾았을 수도 있으니 원문도 확인하세요).",
          confidence: "중간 — 라벨 표기가 다르면 못 찾을 수 있음")
    end

    def check_pii
      return unless @main.ok?

      hits = PiiScanner.scan(@main)
      return if hits.empty?

      @review.add(Finding.new(severity: "CHECK", code: "PII", source_document: @main.label,
                              location: hits.map { |h| h[:locator] }.uniq.first(5).join(", "),
                              extracted_value: hits.map { |h| h[:label] }.uniq.join(" · "),
                              problem: "개인정보로 보이는 값이 #{hits.size}곳 있습니다(값은 표시하지 않습니다)",
                              why_it_matters: "견적서를 결재·공개 문서에 붙일 때 개인정보가 같이 나갈 수 있습니다.",
                              suggested_action: "필요 없는 개인정보는 가린 사본을 쓰세요."))
    end

    # ── 기존 계약 판정기 연결 (복제하지 않고 호출) ─────────────────────
    def link_contract_decision
      supply = value(:supply_amount) || (@items.map(&:amount).compact.sum if @items.any? && @items.none? { |i| i.amount.nil? })
      unless supply&.positive? && @contract_type
        @review.skip("CONTRACT-LINK", @contract_type ? "공급가액을 확정하지 못했습니다" : "계약 유형(물품·용역·공사)을 선택하지 않았습니다")
        return
      end

      result = ContractMethodService.determine(contract_type: @contract_type, estimated_price: supply,
                                               agency_scope: @agency_scope, counterparty_type: @counterparty_type)
      @review.extras[:contract] = { assumed_estimated_price: supply, result: result, from_ai: @from_ai }
    end

    # ── 가격 근거 수준 (적정성 판정 아님) ─────────────────────────────
    def assess_price_evidence
      if @items.empty?
        @review.skip("Q-PRICE-EVIDENCE", "이 견적서의 품목표를 읽지 못해 비교견적과 대조하지 않았습니다")
        return
      end
      comparisons = @documents.drop(1).select(&:ok?).map { |d| [ d, ItemTable.parse(d) ] }
      rows = @items.map do |it|
        others = comparisons.filter_map do |doc, items|
          match = items.find { |o| comparable?(it, o) }
          next unless match && match.unit_price && it.unit_price

          { document: doc.label, unit_price: match.unit_price,
            diff_pct: it.unit_price.zero? ? nil : ((match.unit_price - it.unit_price) * 100.0 / it.unit_price).round(1) }
        end
        { name: it.name, spec: it.spec, unit_price: it.unit_price, comparable: it.spec.present?, others: others }
      end

      level = if comparisons.empty? then "PRICE_EVIDENCE_INSUFFICIENT"
      elsif rows.any? && rows.all? { |r| r[:others].any? } then "PRICE_EVIDENCE_STRONG"
      elsif rows.any? { |r| r[:others].any? } then "PRICE_EVIDENCE_PARTIAL"
      else "NOT_COMPARABLE"
      end
      @review.extras[:price_evidence] = { level: level, label: PRICE_LEVELS.fetch(level), rows: rows,
                                          comparison_count: comparisons.size }
      @review.rules_run += 1
      @review.add(Finding.new(
        severity: level == "PRICE_EVIDENCE_STRONG" ? "PASS" : "CHECK", code: "Q-PRICE-EVIDENCE",
        source_document: @main.label, extracted_value: level,
        problem: "가격 근거: #{PRICE_LEVELS.fetch(level)}",
        why_it_matters: "이 결과는 가격이 적정한지에 대한 판정이 아닙니다. 가격을 설명할 근거가 얼마나 있는지만 봅니다.",
        suggested_action: level == "PRICE_EVIDENCE_STRONG" ? nil : "같은 규격의 비교견적·조달청 가격정보·이전 계약단가 중 하나를 근거로 남기세요.",
        confidence: "높음"
      ))
    end

    # 같은 물건으로 볼 수 있을 때만 비교한다: 품명·규격이 공백 무시하고 같아야 한다. 규격이 없으면 비교하지 않는다.
    def comparable?(a, b)
      return false if a.spec.blank? || b.spec.blank?

      norm(a.name) == norm(b.name) && norm(a.spec) == norm(b.spec)
    end

    def norm(s) = s.to_s.gsub(/[\s·,()]/, "").downcase
  end
end
