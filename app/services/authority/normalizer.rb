# frozen_string_literal: true

# P1.5 §21 — 정규화.
#
# 목적: 공백·HTML wrapper·줄바꿈 변화가 "새 법령 개정"으로 오인되지 않게 한다.
# 금지: 원문의 **의미**를 바꾸는 정규화. 조문 번호·금액·날짜·단서는 손대지 않는다.
module Authority
  class Normalizer
    # 의미 없는 껍데기만 제거한다.
    STRIP_TAGS = %w[script style nav header footer iframe noscript].freeze

    class << self
      def normalize(raw, format: :text)
        text = format == :html ? strip_html(raw) : raw.to_s
        canonicalize(text)
      end

      def digest(raw, format: :text)
        AuthorityVersion.digest(normalize(raw, format: format))
      end

      private

      def strip_html(raw)
        s = raw.to_s
        STRIP_TAGS.each { |tag| s = s.gsub(%r{<#{tag}\b.*?</#{tag}>}im, " ") }
        s = s.gsub(/<br\s*\/?>/i, "\n").gsub(%r{</(p|div|li|tr|h[1-6])>}i, "\n")
        s = s.gsub(/<[^>]+>/m, " ")
        CGI.unescapeHTML(s)
      end

      def canonicalize(text)
        text
          .unicode_normalize(:nfc)          # 한글 자모 분리 표기 통일
          .gsub("\r\n", "\n").gsub("\r", "\n")  # 줄바꿈 통일
          .gsub(/ /, " ")              # NBSP → 일반 공백
          .gsub(/[ \t]+/, " ")              # 연속 공백 축약
          .gsub(/ *\n */, "\n")             # 줄 앞뒤 공백 제거
          .gsub(/\n{3,}/, "\n\n")           # 3줄 이상 빈 줄 축약
          .strip
      end
    end
  end
end
