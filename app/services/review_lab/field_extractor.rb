# frozen_string_literal: true

require "bigdecimal"

module ReviewLab
  # 라벨 사전으로 문서에서 값을 읽는다. **규칙만 쓴다**(AI 없음).
  #
  # 설계 원칙
  #   · 라벨은 «문장 속 낱말» 이 아니라 «항목 머리» 일 때만 인정한다.
  #     «추정가격이 2천만원 이하인 경우…» 같은 설명문을 값으로 읽으면 상호대조가 거짓 충돌을 낸다.
  #     그래서 라벨 앞에는 번호·글머리표만, 라벨 뒤에는 구분자(: | 표 칸)가 와야 한다.
  #   · 숫자·날짜형 항목은 값이 실제로 해석될 때만 채택한다. 해석 못 하면 raw 만 남기고 value=nil(UNKNOWN).
  #   · 한 문서에서 같은 항목이 여러 번 나오면 전부 모은다 — 문서 **안의** 모순도 잡기 위해서다.
  class FieldExtractor
    TYPES = %i[amount date datetime days quantity text].freeze

    # key => [표시명, 타입, 라벨들]
    # 라벨은 긴 것부터 맞춘다(«입찰서 제출 마감» 이 «마감» 보다 먼저).
    PACKAGE_FIELDS = {
      project_name:     [ "사업명", :text, %w[사업명 구매건명 건명 과업명 용역명 공사명 계약건명] ],
      notice_no:        [ "공고번호", :text, [ "공고번호", "공고 번호" ] ],
      estimated_price:  [ "추정가격", :amount, %w[추정가격] ],
      base_price:       [ "기초금액", :amount, %w[기초금액] ],
      budget:           [ "사업예산", :amount, %w[사업예산 소요예산 배정예산 예산액] ],
      quantity:         [ "수량", :quantity, %w[구매수량 납품수량 수량] ],
      contract_period:  [ "계약기간", :days, %w[계약기간 사업기간 과업기간 용역기간 공사기간] ],
      delivery_deadline: [ "납품기한", :days, %w[납품기한 납품기간 납기] ],
      announce_date:    [ "공고일", :date, %w[공고일자 공고일] ],
      bid_period:       [ "입찰서 제출기간", :text, [ "전자입찰서 제출기간", "입찰서 제출기간", "입찰서제출기간", "입찰기간" ] ],
      bid_deadline:     [ "입찰서 제출 마감", :datetime, [ "입찰서 제출 마감일시", "입찰서 제출 마감", "입찰서 제출마감", "입찰마감일시", "입찰 마감", "입찰마감" ] ],
      opening:          [ "개찰일시", :datetime, [ "개찰일시", "개찰 일시", "개찰일" ] ],
      site_briefing:    [ "현장설명", :text, [ "현장설명회", "현장설명" ] ],
      qualification:    [ "입찰참가자격", :text, [ "입찰참가자격", "입찰 참가자격", "참가자격" ] ],
      license:          [ "업종·면허", :text, [ "업종 및 면허", "업종·면허", "업종(면허)", "면허", "업종" ] ],
      region:           [ "지역제한", :text, [ "지역제한", "지역 제한" ] ],
      award_method:     [ "낙찰방법", :text, [ "낙찰자 결정방법", "낙찰자결정방법", "낙찰방법" ] ],
      contract_method:  [ "계약방법", :text, %w[계약방법 계약방식] ],   # «입찰방법: 전자입찰» 은 다른 개념 — 섞으면 협상 판정을 놓친다
      joint_contract:   [ "공동수급", :text, [ "공동수급", "공동계약" ] ],
      bid_bond:         [ "입찰보증금", :text, %w[입찰보증금] ],
      required_docs:    [ "제출서류", :text, %w[제출서류] ],
      contact:          [ "문의처", :text, %w[문의처 담당자 연락처] ],
      vat_note:         [ "부가세 표기", :text, [ "부가가치세", "부가세" ] ]
    }.freeze

    QUOTE_FIELDS = {
      company_name:      [ "업체명", :text, [ "공급자 상호", "상호", "업체명", "회사명" ] ],
      business_no:       [ "사업자등록번호", :text, [ "사업자등록번호", "사업자 등록번호", "등록번호" ] ],
      representative:    [ "대표자", :text, [ "대표자", "대표" ] ],
      quote_date:        [ "견적일", :date, [ "견적일자", "견적일", "작성일자", "작성일" ] ],
      validity:          [ "유효기간", :days, [ "견적 유효기간", "견적유효기간", "유효기간" ] ],
      delivery_deadline: [ "납품기한", :days, %w[납품기한 납품기간 납기] ],
      delivery_terms:    [ "납품조건", :text, %w[납품조건 인도조건 납품장소] ],
      payment_terms:     [ "결제조건", :text, %w[결제조건 대금지급조건 지급조건] ],
      supply_amount:     [ "공급가액", :amount, [ "공급가액 합계", "공급가액", "공급가" ] ],
      vat_amount:        [ "부가세", :amount, [ "부가가치세", "부가세", "세액" ] ],
      total_amount:      [ "합계금액", :amount, [ "합계금액", "총 견적금액", "견적금액", "총액", "합계" ] ],
      remarks:           [ "비고", :text, %w[비고 특기사항] ]
    }.freeze

    # P4 §5 — 사업계획서 + 산출기초(산출내역) 슬라이스.
    # 라벨은 **실제 문서에 항목 머리로 등장하는 말**만 넣는다. 「예상」·「추정」 같은 수식어는
    # 값 해석을 흔들 뿐 항목 머리가 아니다.
    # ⚠️ `account_subject`(예산과목)는 **표시용**이다 — 이 슬라이스는 과목을 판정하지 않는다(§16).
    BUDGET_FIELDS = {
      project_name:    [ "사업명", :text, [ "사업명", "세부사업명", "과업명", "사업 명", "구매건명", "건명" ] ],
      purpose:         [ "사업목적", :text, [ "사업목적", "추진목적", "사업 목적", "추진 배경", "목적" ] ],
      department:      [ "담당부서", :text, [ "담당부서", "주관부서", "부서명", "담당자" ] ],
      fiscal_year:     [ "회계연도", :text, [ "회계연도", "회계 연도", "예산연도" ] ],
      project_period:  [ "사업기간", :days, [ "사업기간", "추진기간", "집행기간", "사업 기간", "용역기간", "공사기간" ] ],
      total_cost:      [ "총사업비", :amount, [ "총사업비", "총 사업비", "사업비", "총소요액", "총소요예산", "소요액" ] ],
      budget_amount:   [ "예산액", :amount, [ "예산현액", "배정예산", "확보예산", "예산액", "본예산" ] ],
      supply_amount:   [ "공급가액", :amount, [ "공급가액 합계", "공급가액", "공급가" ] ],
      vat_amount:      [ "부가세", :amount, [ "부가가치세", "부가세", "세액" ] ],
      grand_total:     [ "합계", :amount, [ "합계금액", "총계", "총액", "합계" ] ],
      # «과목» 단독은 넣지 않는다 — 학교 문서의 «과목» 은 교과목명일 수 있고, 그것을 예산과목으로
      # 표시하면 화면이 거짓을 말한다. 못 읽는 것보다 틀리게 읽는 것이 나쁘다(독립 리뷰 R1).
      account_subject: [ "예산과목", :text, [ "예산과목", "예산 과목", "세출과목", "세출 과목", "세부항목" ] ],
      basis_note:      [ "산출근거", :text, [ "산출근거", "산출기초", "산출내역", "적산근거" ] ]
    }.freeze

    # 라벨 앞에 올 수 있는 것: 번호(1. 가. (1) ①)·글머리표. 그 밖의 글자가 앞에 있으면 문장 속 낱말이다.
    PREFIX = /\A\s*(?:(?:\d{1,2}|[가나다라마바사아자차카타파하])[.)]\s*|\(\d{1,2}\)\s*|[①-⑳]\s*|[○●□■▪•*\-·▶]\s*)*/

    def self.extract(document, fields) = new(document, fields).extract

    def initialize(document, fields)
      @document = document
      @fields = fields
    end

    # => { key => [ExtractedField, …] } (등장 순서)
    def extract
      out = Hash.new { |h, k| h[k] = [] }
      @document.segments.each do |seg|
        cells = seg[:cells].presence || [ seg[:text] ]
        cells.each_with_index do |cell, ci|
          @fields.each do |key, (_name, type, labels)|
            label = matching_label(cell, labels)
            next unless label

            raw = value_after(cell, label, cells, ci, type)
            next if raw.blank?

            value = self.class.normalize(type, raw)
            next if value.nil? && type != :text   # 숫자·날짜형은 해석될 때만 채택(설명문 오인 방지)

            out[key] << ExtractedField.new(key: key, value: value, raw: raw.truncate(120), document: @document.label,
                                           locator: seg[:locator], origin: :rule, label: label)
          end
        end
      end
      out
    end

    private

    def matching_label(cell, labels)
      body = cell.sub(PREFIX, "")
      labels.sort_by { |l| -l.length }.find do |l|
        next false unless body.start_with?(l)

        rest = body[l.length..]
        # 라벨 뒤 괄호 설명은 허용: «추정가격(부가가치세 제외): …»
        rest = rest.sub(/\A\s*\([^)]{0,30}\)/, "")
        rest.empty? || rest.match?(/\A\s*[:：|]/) || rest.match?(/\A\s+\S/)
      end
    end

    # 칸이 라벨뿐이면 값은 같은 행의 다음 비어 있지 않은 칸이다(표 형식).
    def value_after(cell, label, cells, ci, type)
      body = cell.sub(PREFIX, "")[label.length..].sub(/\A\s*\([^)]{0,30}\)/, "")
      if body.strip.empty?
        nxt = cells[(ci + 1)..].to_a.find(&:present?)
        return nxt.to_s.strip
      end
      if body.match?(/\A\s*[:：|]/)
        return body.sub(/\A\s*[:：|]\s*/, "").strip
      end
      # 공백만 있는 구분은 숫자·날짜형에서만 인정한다 — 텍스트형은 «계약기간 중 …» 같은 문장을 값으로 오인한다.
      return nil if type == :text

      body.strip
    end

    class << self
      def normalize(type, raw)
        case type
        when :amount   then parse_amount(raw)
        when :date     then parse_date(raw)
        when :datetime then parse_datetime(raw)
        when :days     then parse_days(raw)
        when :quantity then parse_quantity(raw)
        when :text     then normalize_text(raw)
        end
      end

      # «45,000,000원» «금 45,000,000원» «4,500만원» «1억 2,000만원» «2천만원» «1.5억원» «3천원»
      # 한글 수사(«금사천오백만원»)·단위 없는 소수는 읽지 않는다 → nil(UNKNOWN). 틀리게 읽는 것보다 모른다가 낫다.
      SMALL_UNITS = { "천" => 1_000, "백" => 100, "십" => 10 }.freeze
      AMOUNT_TOKEN = /\A\s*(\d[\d,]*(?:\.\d+)?)?\s*(억|만|천|백|십)/

      # 한국식 단위는 «억·만» 묶음 안에서 «천·백·십» 계수를 모은다: «2천5백만» = (2,000+500)×10,000.
      def parse_amount(raw)
        s = raw.to_s.sub(/\A\s*(?:금|₩|\\)\s*/, "")
        return nil unless s.match?(/\A\d/)

        total = BigDecimal(0)
        small = BigDecimal(0)
        saw_unit = false
        while (m = s.match(AMOUNT_TOKEN))
          return nil if m[1] && !well_grouped?(m[1])

          n = m[1] ? BigDecimal(m[1].delete(",")) : nil
          case m[2]
          when "억", "만"
            coef = small + (n || 0)
            coef = BigDecimal(1) if coef.zero?
            total += coef * (m[2] == "억" ? 100_000_000 : 10_000)
            small = BigDecimal(0)
          else
            small += (n || 1) * SMALL_UNITS.fetch(m[2])
          end
          saw_unit = true
          s = m.post_match
        end
        if (m = s.match(/\A\s*(\d[\d,]*)(\.\d+)?/))
          return nil if m[2]                      # 단위 없는 소수(«1.5»)는 뜻이 불명확
          return nil unless well_grouped?(m[1])   # «45,000,00» 을 45,000 으로 잘라 읽지 않는다

          total += m[1].delete(",").to_i
          s = m.post_match
        end
        total += small
        rest = s.strip
        # 끝은 «원…» 이거나 구분 기호 — «12대» 처럼 다른 단위가 붙으면 금액이 아니다.
        return nil unless rest.empty? || rest.match?(%r{\A(?:원|정|[\s(,/·.;])})
        return nil if total.zero? && raw.to_s !~ /\A\s*(?:금|₩)?\s*0/

        total.to_i
      end

      # 쉼표는 세 자리 묶음일 때만 — 틀린 묶음은 그럴듯한 틀린 값을 만들므로 UNKNOWN 으로 둔다.
      def well_grouped?(num) = !num.include?(",") || num.match?(/\A\d{1,3}(?:,\d{3})+(?:\.\d+)?\z/)

      DATE_RE = /(\d{4})\s*[.\-\/년]\s*(\d{1,2})\s*[.\-\/월]\s*(\d{1,2})\s*[.일]?/

      EXCEL_EPOCH = Date.new(1899, 12, 30)

      def parse_date(raw)
        # XLSX 날짜 셀은 일련번호(예: 46275)로 저장된다. 날짜형 라벨 뒤의 5자리 수만 날짜로 읽는다.
        if (serial = raw.to_s.strip[/\A(\d{5})(?:\.\d+)?\z/, 1]) && serial.to_i.between?(30_000, 80_000)
          return EXCEL_EPOCH + serial.to_i
        end
        m = raw.to_s.match(DATE_RE) or return nil
        Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
      rescue Date::Error
        nil
      end

      # 시각이 없으면 날짜만(시각 모름)으로 둔다 — 00:00 으로 채우면 경계 판정이 거짓이 된다.
      def parse_datetime(raw)
        s = raw.to_s
        m = s.match(DATE_RE) or return nil
        date = Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
        after = s[m.end(0)..].to_s
        t = after.match(/\A[^\d~]{0,8}?(\d{1,2})\s*(?::|시)\s*(\d{2})?/)
        return { date: date, time: nil } unless t

        hour = t[1].to_i
        min = t[2].to_i
        hour += 12 if after[0, t.begin(1)].include?("오후") && hour < 12
        hour = 0 if after[0, t.begin(1)].include?("오전") && hour == 12
        return { date: date, time: nil } unless hour.between?(0, 24) && min.between?(0, 59)

        { date: date, time: format("%02d:%02d", hour, min) }
      rescue Date::Error
        nil
      end

      # «계약일로부터 30일» «착수일부터 45일 이내» «30일» → { days:, base: }
      # «2026. 10. 1. ~ 2026. 10. 30.» → { from:, to: } · «2026년 11월 30일까지» → { until: }
      # 일수는 값의 **맨 앞**(기산일 표현 뒤)에 있을 때만 읽는다 — «계약기간 만료 후 14일 이내 대금 지급» 같은
      # 문장 속 «N일» 이나 날짜의 «30일» 을 기간으로 오독하지 않기 위해서다.
      # 기산일은 닫힌 목록만 — 열어 두면 «만료 후 14일 이내» 같은 문장을 기간으로 읽는다.
      DAYS_BASES = "계약\\s*체결일|계약일|착수일|착공일|발주일|통보일|견적\\s*제출일|견적일|납품\\s*요구일"
      DAYS_RE = /\A\s*(?:(#{DAYS_BASES}|발주|계약|착공|착수)\s*(?:로부터|으로부터|부터|기준|후)?\s*)?\(?\s*(\d{1,4})\s*일(?!\s*[.)]?\s*\d)/

      def parse_days(raw)
        s = raw.to_s
        dates = s.scan(DATE_RE)
        if dates.size >= 2
          from = Date.new(*dates[0].map(&:to_i)) rescue nil
          to = Date.new(*dates[1].map(&:to_i)) rescue nil
          return { from: from, to: to } if from && to
        end
        if dates.size == 1 && s.match?(/\A\s*#{DATE_RE.source}/o)
          d = parse_date(s)
          return d ? { until: d } : nil
        end
        m = s.match(DAYS_RE) or return nil
        { days: m[2].to_i, base: m[1]&.gsub(/\s/, "") }
      end

      QTY_UNITS = %w[대 개 식 EA ea 세트 SET set 본 매 권 조 개소 명 식 m ㎡ m² 롤 박스 BOX kg].freeze

      def parse_quantity(raw)
        m = raw.to_s.match(/\A\s*(\d[\d,]*)\s*([^\d\s,()]{0,4})/) or return nil
        { qty: m[1].delete(",").to_i, unit: m[2].presence }
      end

      def normalize_text(raw)
        raw.to_s.gsub(/\s+/, " ").strip.presence
      end
    end
  end
end
