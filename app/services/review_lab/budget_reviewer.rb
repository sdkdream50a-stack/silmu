# frozen_string_literal: true

module ReviewLab
  # P4 §5·§6·§7 — 사업계획서 + 산출기초(산출내역) 검증기.
  #
  # 왜 이 문서 조합인가 (근거 = harness artifacts/03_SLICE_SELECTION.md — 점수로 골랐다)
  #   검사가 **순수 산술**이라 법적 판단이 0 이고, 산술은 학교회계든 지자체든 같아서
  #   §21-7(학교/지자체 기준 혼입 0)을 필터가 아니라 **구조로** 만족한다.
  #   반대로 품의서·지출결의서는 17개 교육규칙에서 전결 한도(50/200/500만원)와 별지 서식이
  #   실제로 갈리는 것을 측정했기 때문에 **의도적으로 제외**했다.
  #
  # 이 검증기가 하지 않는 것 (화면에도 같은 말을 적는다)
  #   · 예산과목(목·세목) 추천·확정 — HUMAN_ONLY. 읽은 과목은 **표시만** 한다.
  #   · 「적정/부적정/위법/집행 가능」 단정 — 어떤 경로로도 내지 않는다.
  #   · 집행 적법성·가격 적정성 판단.
  #
  # 판정 권위
  #   산술 모순만 BLOCK 이다. 「예산액을 넘었다」처럼 **추가 절차가 있을 수 있는** 것은 WARN,
  #   코드가 결론을 못 내는 것은 CHECK. AI 는 `Finding` 이 구조적으로 CHECK 로 고정한다.
  class BudgetReviewer
    VAT_RATE = Rational(1, 10)
    VAT_TOLERANCE = 10          # 원 — 원 단위 절사 관행
    SUM_TOLERANCE = 1           # 원 — 행 금액 원 단위 절사
    PLAN_ROLE = "project_plan"
    BASIS_ROLE = "cost_basis"

    REQUIRED = { project_name: "사업명", total_cost: "총사업비", project_period: "사업기간" }.freeze

    def self.call(**kwargs) = new(**kwargs).call

    # documents: [사업계획서, 산출기초, …] (DocumentArtifact). 둘 중 하나만 있어도 돈다.
    def initialize(documents:, today: Date.current)
      @documents = documents
      @today = today
    end

    def call
      @review = DocumentReview.new(kind: :budget, documents: @documents)
      @fields = {}
      @items = {}
      readable = @review.readable_documents
      return @review if readable.empty?

      readable.each do |doc|
        f = FieldExtractor.extract(doc, FieldExtractor::BUDGET_FIELDS)
        @review.fields[doc.label] = f
        @fields[doc] = f
        @items[doc] = ItemTable.parse(doc)
      end

      check_item_arithmetic
      check_basis_subtotal
      check_vat
      check_cross_document_total
      check_budget_envelope
      check_cross_document_identity
      check_dates
      check_required
      note_account_subject
      check_pii
      @review
    end

    private

    # ── 공통 ─────────────────────────────────────────────────────────
    def plan  = @fields.keys.find { |d| d.role == PLAN_ROLE }
    def basis = @fields.keys.find { |d| d.role == BASIS_ROLE }

    def first_field(doc, key) = doc && @fields[doc]&.dig(key)&.first
    def first_value(doc, key) = first_field(doc, key)&.value

    # 어느 문서든 상관없이 처음 읽힌 값 — 단일 문서만 올린 경우에 쓴다.
    def any_field(key)
      @fields.each_value do |f|
        got = f[key]&.first
        return got if got
      end
      nil
    end

    def won(n) = n.nil? ? "—" : "#{n.to_i.to_fs(:delimited)}원"

    def add(severity:, code:, document: nil, **rest)
      @review.add(Finding.new(severity: severity, code: code, source_document: document&.label, **rest))
    end

    def ran(n = 1) = @review.rules_run += n

    # ── §6-1. 수량 × 단가 = 금액 ─────────────────────────────────────
    def check_item_arithmetic
      rows = @items.flat_map { |doc, items| items.map { |i| [ doc, i ] } }
      checkable = rows.select { |_d, i| i.qty && i.unit_price && i.amount }
      if checkable.empty?
        @review.skip("B-ROW", rows.empty? ? "품목표(품명·수량·단가 머리행)를 찾지 못했습니다" : "행에 수량·단가·금액이 모두 있는 품목이 없습니다")
        return
      end

      ran
      # 수량·단가·금액 중 하나라도 못 읽은 행은 **검산되지 않았다**. 그 사실을 적지 않으면
      # «N개 품목 PASS» 가 표 전체를 검사한 것처럼 읽힌다(독립 리뷰 R2 — 무음 누락).
      unchecked = rows.size - checkable.size
      if unchecked.positive?
        add(severity: "CHECK", code: "B-ROW-COVERAGE", extracted_value: "#{checkable.size}/#{rows.size}개 행",
            problem: "품목 #{rows.size}개 중 #{unchecked}개는 수량·단가·금액을 모두 읽지 못해 검산하지 못했습니다",
            why_it_matters: "검산한 행만 «맞다» 고 말할 수 있습니다. 읽지 못한 행은 검사 결과에 포함되지 않았습니다.",
            suggested_action: "해당 행의 수량·단가·금액이 원문에 모두 적혀 있는지 확인하세요.")
      end
      bad = checkable.reject { |_d, i| (i.qty * i.unit_price - i.amount).abs <= SUM_TOLERANCE }
      if bad.empty?
        add(severity: "PASS", code: "B-ROW", extracted_value: "#{checkable.size}개 품목",
            problem: "모든 행에서 수량 × 단가 = 금액")
        return
      end

      bad.each do |doc, i|
        add(severity: "BLOCK", code: "B-ROW", document: doc, location: i.locator,
            extracted_value: "#{i.name} — #{i.qty} × #{won(i.unit_price)} = #{won(i.amount)}",
            problem: "수량 × 단가가 금액과 맞지 않습니다(계산값 #{won(i.qty * i.unit_price)})",
            why_it_matters: "산출기초의 행 금액이 틀리면 총사업비·예산요구액이 함께 틀립니다.",
            suggested_action: "원문의 수량·단가·금액을 다시 확인하세요.",
            confidence: i.confidence)
      end
    end

    # ── §6-2. Σ 행 금액 = 산출기초 합계 ──────────────────────────────
    def check_basis_subtotal
      doc = basis || @items.keys.find { |d| @items[d].present? }
      items = doc ? @items[doc] : []
      # ⚠️ 비교 대상은 **공급가액**이 우선이다. 부가세가 따로 적힌 문서에서 «합계»(=공급가액+부가세)와
      #    품목 합을 견주면 부가세만큼 어긋나 **거짓 BLOCK** 이 난다. 공급가액이 없는데 부가세가
      #    있으면 무엇과 견줘야 할지 정할 수 없으므로 검사하지 않고 그 사실을 적는다.
      supply = first_value(doc, :supply_amount)
      vat = first_value(doc, :vat_amount)
      stated = supply || (vat.nil? ? (first_value(doc, :grand_total) || first_value(doc, :total_cost)) : nil)
      if items.empty? || items.any? { |i| i.amount.nil? } || stated.nil?
        reason = if items.empty?
          "품목표(품명·수량·단가 머리행)를 찾지 못했습니다"
        elsif items.any? { |i| i.amount.nil? }
          "품목 금액을 모두 읽지 못했습니다"
        elsif vat
          "부가세는 있고 공급가액은 없어, 품목 합을 어느 값과 견줄지 정하지 못했습니다"
        else
          "산출기초의 합계 항목을 찾지 못했습니다"
        end
        @review.skip("B-SUM", reason)
        return
      end

      ran
      sum = items.sum(&:amount)
      if (sum - stated).abs <= SUM_TOLERANCE
        add(severity: "PASS", code: "B-SUM", extracted_value: won(stated),
            problem: "#{supply ? '공급가액' : '합계'} = 품목 금액의 합")
      else
        add(severity: "BLOCK", code: "B-SUM", document: doc,
            location: (first_field(doc, :supply_amount) || first_field(doc, :grand_total))&.locator,
            extracted_value: "적힌 값 #{won(stated)} · 품목 합 #{won(sum)}",
            problem: "적힌 #{supply ? '공급가액' : '합계'}가 품목 금액의 합과 다릅니다(차이 #{won((sum - stated).abs)})",
            why_it_matters: "합계가 다르면 어느 쪽이 맞는지 결재선에서 판단할 수 없습니다.",
            suggested_action: "빠지거나 중복된 행이 없는지 확인하세요.")
      end
    end

    # ── §6-3. 공급가액 + 부가세 = 합계 ───────────────────────────────
    # ⚠️ 세 값은 **한 문서 안에서** 읽는다. 문서를 넘나들며 모으면 사업계획서의 «총액» 과
    #    산출기초의 «공급가액» 을 더해 비교하게 되어 거짓 BLOCK 이 난다(독립 리뷰 R1).
    def check_vat
      # 둘 다 가진 문서가 있으면 그 문서다. 공급가액만 가진 문서를 먼저 집으면(사업계획서가
      # 공급가액을 적은 경우) 산출기초의 부가세·합계 검산이 통째로 사라진다(독립 리뷰 R2).
      doc = @fields.keys.find { |d| @fields[d][:supply_amount]&.first && @fields[d][:vat_amount]&.first } ||
            @fields.keys.find { |d| @fields[d][:supply_amount]&.first } ||
            @fields.keys.find { |d| @fields[d][:vat_amount]&.first }
      supply = first_value(doc, :supply_amount)
      vat = first_value(doc, :vat_amount)
      total = first_value(doc, :grand_total)
      if supply.nil? || vat.nil?
        @review.skip("B-VAT", "공급가액 또는 부가세를 찾지 못했습니다")
        @review.skip("B-TOTAL", "공급가액 또는 부가세를 찾지 못해 합계를 검산하지 못했습니다")
      else
        ran
        expected = (supply * VAT_RATE).to_i
        if (vat - expected).abs <= VAT_TOLERANCE
          add(severity: "PASS", code: "B-VAT", extracted_value: won(vat), problem: "부가세 = 공급가액의 10%")
        else
          add(severity: "WARN", code: "B-VAT", document: doc, location: first_field(doc, :vat_amount)&.locator,
              extracted_value: "적힌 부가세 #{won(vat)} · 10% 계산값 #{won(expected)}",
              problem: "부가세가 공급가액의 10%와 다릅니다",
              why_it_matters: "면세·영세율이면 맞을 수 있습니다 — 코드가 그것까지는 판정하지 않습니다.",
              suggested_action: "면세 대상인지, 단순 계산 오류인지 확인하세요.")
        end
      end

      return if supply.nil? || vat.nil?
      if total.nil?
        # 조기 종료가 «검사했는데 문제 없음» 으로 읽히면 안 된다 — 왜 못 돌렸는지 남긴다.
        @review.skip("B-TOTAL", "합계 항목을 찾지 못해 «공급가액 + 부가세» 와 대조하지 못했습니다")
        return
      end

      ran
      if (supply + vat - total).abs <= SUM_TOLERANCE
        add(severity: "PASS", code: "B-TOTAL", extracted_value: won(total), problem: "합계 = 공급가액 + 부가세")
      else
        add(severity: "BLOCK", code: "B-TOTAL", document: doc, location: first_field(doc, :grand_total)&.locator,
            extracted_value: "적힌 합계 #{won(total)} · 공급가액+부가세 #{won(supply + vat)}",
            problem: "합계가 공급가액 + 부가세와 다릅니다",
            why_it_matters: "결재 금액과 지출 금액이 갈립니다.",
            suggested_action: "세 값 중 어느 것이 맞는지 원문에서 확인하세요.")
      end
    end

    # ── §6-4. 문서 간 금액 일치 — 산출기초 합계 = 사업계획서 총사업비 ──
    def check_cross_document_total
      p_doc = plan
      b_doc = basis
      plan_total = first_value(p_doc, :total_cost)
      basis_total = comparable_total(b_doc)
      if plan_total.nil? || basis_total.nil?
        reason = if plan_total.nil?
          "사업계획서 총사업비를 찾지 못해 문서 간 대조를 하지 않았습니다"
        elsif first_value(b_doc, :vat_amount)
          "산출기초에 부가세는 있고 합계 항목이 없어, 총사업비를 어느 값과 견줄지 정하지 못했습니다"
        else
          "산출기초 합계를 확정하지 못해 문서 간 대조를 하지 않았습니다"
        end
        @review.skip("B-CROSS-TOTAL", reason)
        return
      end

      ran
      if (plan_total - basis_total).abs <= SUM_TOLERANCE
        add(severity: "PASS", code: "B-CROSS-TOTAL", extracted_value: won(plan_total),
            problem: "사업계획서 총사업비 = 산출기초 합계")
      else
        add(severity: "BLOCK", code: "B-CROSS-TOTAL", document: p_doc,
            location: first_field(p_doc, :total_cost)&.locator,
            extracted_value: "사업계획서 #{won(plan_total)} · 산출기초 #{won(basis_total)}",
            problem: "두 문서의 금액이 다릅니다(차이 #{won((plan_total - basis_total).abs)})",
            why_it_matters: "첨부 산출기초와 본문 총사업비가 다르면 그대로 결재될 수 없습니다.",
            suggested_action: "어느 문서가 최신인지 확인하고 한쪽을 맞추세요.")
      end
    end

    # 사업계획서의 «총사업비» 는 관행상 **부가세를 포함한** 금액이다. 그래서 산출기초에서도
    # 부가세 포함 합계를 골라야 한다. 부가세가 적혀 있는데 합계 라벨이 없으면 공급가액(부가세 제외)과
    # 견주게 되어 **정상 문서에 거짓 BLOCK** 이, 반대로 부가세를 빠뜨린 계획서에 **거짓 PASS** 가 난다.
    # 그래서 그 경우는 «비교 불가» 로 둔다(독립 리뷰 R1).
    def comparable_total(doc)
      return nil if doc.nil?

      grand = first_value(doc, :grand_total)
      return grand if grand
      return nil if first_value(doc, :vat_amount)

      items = @items[doc]
      first_value(doc, :supply_amount) ||
        (items.present? && items.none? { |i| i.amount.nil? } ? items.sum(&:amount) : nil)
    end

    # ── §6-5. 총사업비 ≤ 예산액 ──────────────────────────────────────
    def check_budget_envelope
      cost = any_field(:total_cost)&.value
      budget = any_field(:budget_amount)&.value
      if cost.nil? || budget.nil?
        @review.skip("B-ENVELOPE", "총사업비 또는 예산액을 찾지 못했습니다")
        return
      end

      ran
      if cost <= budget
        add(severity: "PASS", code: "B-ENVELOPE", extracted_value: "#{won(cost)} ≤ #{won(budget)}",
            problem: "총사업비가 적힌 예산액 안입니다")
      else
        # 「위법」이 아니다 — 추경·전용·이월 같은 절차가 있을 수 있다. 그래서 BLOCK 이 아니라 WARN.
        add(severity: "WARN", code: "B-ENVELOPE", location: any_field(:total_cost)&.locator,
            extracted_value: "총사업비 #{won(cost)} · 예산액 #{won(budget)}",
            problem: "총사업비가 적힌 예산액을 #{won(cost - budget)} 넘습니다",
            why_it_matters: "예산 범위를 넘는 지출원인행위는 별도 절차(전용·추경 등)가 필요할 수 있습니다. 이 도구는 그 절차를 판정하지 않습니다.",
            suggested_action: "예산액이 최신인지, 별도 절차가 진행 중인지 확인하세요.")
      end
    end

    # ── §6-6. 사업명 문서 간 일치 ────────────────────────────────────
    def check_cross_document_identity
      named = @fields.filter_map { |doc, f| [ doc, f[:project_name]&.first ] if f[:project_name]&.first }
      if named.size < 2
        @review.skip("B-NAME", "사업명을 읽은 문서가 2개 미만이라 문서 간 대조를 하지 않았습니다")
        return
      end

      ran
      norm = ->(s) { s.to_s.gsub(/[\s·,()\[\]「」'"]/, "") }
      values = named.map { |_d, f| norm.call(f.value) }.uniq
      if values.size == 1
        add(severity: "PASS", code: "B-NAME", extracted_value: named.first[1].value,
            problem: "문서 #{named.size}건의 사업명이 같습니다")
      else
        add(severity: "WARN", code: "B-NAME",
            location: named.map { |_d, f| f.locator }.compact.uniq.first(3).join(", "),
            extracted_value: named.map { |d, f| "#{d.label}: #{f.value}" }.join(" · "),
            problem: "문서마다 사업명이 다릅니다",
            why_it_matters: "같은 사업의 첨부인지 확인되지 않으면 산출기초를 근거로 쓸 수 없습니다.",
            suggested_action: "서로 다른 사업의 문서가 섞이지 않았는지 확인하세요.")
      end
    end

    # ── §6-7. 사업기간 ───────────────────────────────────────────────
    def check_dates
      periods = @fields.filter_map { |doc, f| [ doc, f[:project_period]&.first ] if f[:project_period]&.first }
      ranged = periods.select { |_d, f| f.value.is_a?(Hash) && f.value[:from] && f.value[:to] }
      if ranged.empty?
        @review.skip("B-PERIOD", periods.empty? ? "사업기간을 찾지 못했습니다" : "사업기간이 «시작~종료» 형태가 아니라 순서를 검사하지 않았습니다")
        return
      end

      ran
      reversed = ranged.select { |_d, f| f.value[:to] < f.value[:from] }
      if reversed.any?
        reversed.each do |doc, f|
          add(severity: "BLOCK", code: "B-PERIOD", document: doc, location: f.locator,
              extracted_value: f.raw,
              problem: "사업기간의 종료일이 시작일보다 빠릅니다",
              why_it_matters: "기간이 뒤집혀 있으면 계약·검수 기한 산정이 전부 어긋납니다.",
              suggested_action: "시작일·종료일을 확인하세요.")
        end
      elsif ranged.size >= 2 && ranged.map { |_d, f| [ f.value[:from], f.value[:to] ] }.uniq.size > 1
        add(severity: "WARN", code: "B-PERIOD",
            extracted_value: ranged.map { |d, f| "#{d.label}: #{f.raw}" }.join(" · "),
            problem: "문서마다 사업기간이 다릅니다",
            why_it_matters: "본문과 첨부의 기간이 다르면 어느 쪽 기한으로 집행할지 정해지지 않습니다.",
            suggested_action: "두 문서의 기간을 맞추세요.")
      else
        add(severity: "PASS", code: "B-PERIOD", extracted_value: ranged.first[1].raw,
            problem: "사업기간의 시작·종료 순서가 맞습니다")
      end
    end

    # ── §6-8. 필수항목 누락 ──────────────────────────────────────────
    def check_required
      ran
      missing = REQUIRED.reject { |key, _name| any_field(key) }
      if missing.empty?
        add(severity: "PASS", code: "B-REQUIRED", extracted_value: REQUIRED.values.join(" · "),
            problem: "필수 항목을 모두 찾았습니다")
        return
      end

      add(severity: "WARN", code: "B-REQUIRED",
          extracted_value: missing.values.join(" · "),
          problem: "«#{missing.values.join('»·«')}» 항목을 찾지 못했습니다",
          why_it_matters: "문서에 없는 것일 수도, 라벨이 달라 못 읽은 것일 수도 있습니다 — 둘을 구별하지 못합니다.",
          suggested_action: "원문에 해당 항목이 있는지 확인하세요. 있다면 항목 머리(«사업명:» 처럼)를 명확히 적어 주세요.")
    end

    # ── §16 — 과목은 **표시만** 한다. 판정하지 않는다 ────────────────
    def note_account_subject
      f = any_field(:account_subject)
      @review.skip("B-ACCOUNT", "예산과목(목·세목)의 적정성은 이 검토가 판정하지 않습니다 — 소속 기관 기준으로 담당자가 확인합니다")
      return if f.nil?

      add(severity: "CHECK", code: "B-ACCOUNT", location: f.locator, extracted_value: f.value,
          problem: "문서에 적힌 예산과목입니다(그대로 옮긴 값이며 적정한지는 판정하지 않았습니다)",
          why_it_matters: "학교회계와 지방자치단체의 세출 과목 체계는 다릅니다. 이 도구에는 과목 판정 기능이 없습니다.",
          suggested_action: "소속 기관의 예산편성 기본지침에서 과목을 확인하세요.",
          confidence: "표시만 — 판정 아님")
    end

    def check_pii
      @review.readable_documents.each do |doc|
        hits = PiiScanner.scan(doc)
        next if hits.empty?

        add(severity: "CHECK", code: "PII", document: doc,
            location: hits.map { |h| h[:locator] }.uniq.first(5).join(", "),
            extracted_value: hits.map { |h| h[:label] }.uniq.join(" · "),
            problem: "개인정보로 보이는 값이 #{hits.size}곳 있습니다(값은 표시하지 않습니다)",
            why_it_matters: "예산 문서를 결재·공개 문서에 붙일 때 개인정보가 같이 나갈 수 있습니다.",
            suggested_action: "필요 없는 개인정보는 가린 사본을 쓰세요.")
      end
    end
  end
end
