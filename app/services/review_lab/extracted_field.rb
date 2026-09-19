# frozen_string_literal: true

module ReviewLab
  # 문서에서 읽은 값 하나. value 는 비교용 정규화 값, raw 는 문서에 적힌 그대로다.
  # value 가 nil 이면 «라벨은 찾았지만 값을 해석하지 못했다» — UNKNOWN 이지 0 이 아니다.
  ExtractedField = Struct.new(:key, :value, :raw, :document, :locator, :origin, keyword_init: true) do
    def known? = !value.nil?
    def ai? = origin == :ai
  end
end
