# frozen_string_literal: true

module ReviewLab
  # 견적서·내역서의 품목표를 읽는다(규칙만). 머리행(품명·규격·단위·수량·단가·금액)을 찾고
  # 그 아래 행을 합계 행 전까지 읽는다.
  #
  # PDF 는 칸 경계가 공백이라 빈 칸(규격 없음 등)이 있으면 칸 수가 줄어든다.
  # 그때는 숫자 칸(수량·단가·금액)을 **오른쪽 끝에서** 맞추고 확신도를 낮춘다 —
  # 왼쪽부터 맞추면 단가가 수량 칸으로 밀려 산술 검사가 거짓 오류를 낸다.
  class ItemTable
    COLUMN_WORDS = {
      no:         %w[순번 번호 No NO 연번],
      name:       %w[품명 품목 품목명 제품명 내역 공종 공종명],
      spec:       [ "규격", "사양", "규격및사양", "규격·사양", "모델", "모델명" ],
      unit:       %w[단위],
      qty:        %w[수량],
      unit_price: [ "단가", "단가(원)" ],
      amount:     [ "금액", "금액(원)", "공급가액", "합계금액" ],
      remark:     %w[비고]
    }.freeze
    # 합계 행 판정은 낱말 전체가 일치할 때만 — 접두 일치로 두면 «계량컵»·«계산기» 에서 표 읽기가 멈춘다.
    # 뒤에 괄호 설명(«공급가액(VAT별도)» «부가세(10%)» «소계(A)»)이 붙어도 합계 행이다.
    STOP_ROW = /\A(?:소\s*계|합\s*계|계|공급가액(?:\s*합계)?|부가세|부가가치세|세액|총\s*액|합계금액|총\s*견적금액)\s*(?:\([^)]{0,20}\))?\s*(?:[:：|]|\s+\d|\z)/
    NUMERIC = %i[qty unit_price amount].freeze

    Item = Struct.new(:name, :spec, :unit, :qty, :unit_price, :amount, :locator, :confidence, keyword_init: true)

    def self.parse(document) = new(document).parse

    def initialize(document)
      @document = document
    end

    # => [Item] (머리행을 못 찾으면 [])
    def parse
      segs = @document.segments
      header_idx = segs.index { |s| header_map(s[:cells]).present? }
      return [] unless header_idx

      map = header_map(segs[header_idx][:cells])
      items = []
      segs[(header_idx + 1)..].each do |seg|
        cells = seg[:cells] || [ seg[:text] ]
        first = cells.find(&:present?).to_s
        break if first.match?(STOP_ROW) || (cells.compact.size <= 2 && seg[:text].match?(STOP_ROW))

        item = build_item(cells, map, seg[:locator])
        items << item if item
      end
      items
    end

    private

    def header_map(cells)
      return nil if cells.blank?

      map = {}
      cells.each_with_index do |c, i|
        key = COLUMN_WORDS.find { |_k, words| words.include?(c.to_s.delete(" ")) }&.first
        map[key] ||= i if key
      end
      has_numbers = map.key?(:qty) && (map.key?(:unit_price) || map.key?(:amount))
      has_numbers && map.key?(:name) && map.size >= 3 ? map : nil
    end

    def build_item(cells, map, locator)
      row = !pdf? || cells.size == header_width(map) ? by_position(cells, map) : by_right_alignment(cells, map)
      return nil if NUMERIC.all? { |k| row[k].nil? } # 설명·구분 행

      Item.new(**row, locator: locator, confidence: pdf? ? "중간 — PDF 표를 칸 간격으로 읽음(원문 대조)" : "높음")
    end

    def pdf? = @document.format == :pdf
    def header_width(map) = map.values.max.to_i + 1

    def by_position(cells, map)
      {
        name: text(cells[map[:name]]), spec: text(map[:spec] && cells[map[:spec]]), unit: text(map[:unit] && cells[map[:unit]]),
        qty: number(map[:qty] && cells[map[:qty]]), unit_price: number(map[:unit_price] && cells[map[:unit_price]]),
        amount: number(map[:amount] && cells[map[:amount]])
      }
    end

    # 오른쪽 끝의 연속 숫자 칸을 금액·단가·수량 순으로 채운다. 남은 칸: 번호 → 품명 → (단위 낱말이면 단위) → 규격.
    def by_right_alignment(cells, map)
      rest = cells.dup
      rest.pop while rest.any? && rest.last.blank?
      nums = []
      nums.unshift(rest.pop) while rest.any? && number(rest.last) && nums.size < 3
      numeric_keys = NUMERIC.select { |k| map.key?(k) }
      values = numeric_keys.last(nums.size).zip(nums.map { |n| number(n) }).to_h

      rest.shift if map.key?(:no) && rest.first.to_s.match?(/\A\d{1,3}\z/)
      unit = rest.last if rest.size >= 2 && unit_word?(rest.last)
      rest.pop if unit
      name = rest.shift
      spec = rest.join(" ").presence
      { name: text(name), spec: text(spec), unit: text(unit),
        qty: values[:qty], unit_price: values[:unit_price], amount: values[:amount] }
    end

    UNIT_WORDS = %w[개 대 식 EA ea Ea 세트 SET set 본 매 권 조 개소 m ㎡ m² 롤 박스 BOX kg 명 부 벌 켤레 포 통].freeze
    def unit_word?(s) = UNIT_WORDS.include?(s.to_s.strip)

    def text(v) = v.to_s.strip.presence

    def number(v)
      s = v.to_s.strip
      return nil unless s.match?(/\A-?[\d,]+(\.\d+)?\s*원?\z/)

      s.delete(",").delete("원").to_f.then { |f| f == f.to_i ? f.to_i : f }
    end
  end
end
