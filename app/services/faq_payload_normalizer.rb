# frozen_string_literal: true

# P2 R1 / P-1 — `topics.faqs` (jsonb) 에 **문자열로 갇힌** FAQ 를 배열로 되돌린다.
#
# 배경 (2026-09-06 운영 실측):
#   jsonb 컬럼에 3가지 형태가 섞여 있었다.
#     ARRAY_OK          정상 배열                                        110건
#     STRING_PARSEABLE  jsonb 가 JSON **문자열** (이중 인코딩)              2건 — Topic#faq_list 가 구제 중
#     STRING_BROKEN     Ruby `Hash#inspect` 문자열 (`"k"=>"v"`)            2건 — JSON.parse 실패
#   STRING_BROKEN 은 `Topic#faq_list` 의 `rescue` 가 `[]` 를 돌려주는 바람에
#   공개 토픽 2건(`bid-announcement`·`bidding`)의 **FAQ 9건이 화면·"바로 답"에서 조용히 사라져 있었다.**
#
# ⚠️ 절대 규칙
#   · **내용을 만들지 않는다.** 이 클래스는 표현 형식만 바꾼다. 없는 FAQ 를 채우거나 문구를 고치지 않는다.
#   · **`eval` 을 쓰지 않는다.** inspect 문자열은 임의 Ruby 코드일 수 있다.
#     문자열 리터럴 밖에서만 치환하는 스캐너로 JSON 으로 옮긴 뒤 `JSON.parse` 한다.
#   · 모양이 어긋나면 **고치지 말고 거부한다.** 애매한 payload 를 억지로 살리면 그게 창작이다.
class FaqPayloadNormalizer
  # 반환 status
  #   :already_array  입력이 이미 Array — 손댈 것 없음
  #   :ok             문자열을 배열로 복원했고 모양 검사도 통과
  #   :unparseable    JSON 으로도, inspect 변환 후에도 파싱 불가
  #   :not_array      파싱은 됐으나 최상위가 배열이 아님
  #   :bad_shape      배열이지만 원소가 {question:, answer:} 비어있지 않은 문자열 쌍이 아님
  RECOVERABLE = %i[already_array ok].freeze

  class << self
    # @return [Array(Symbol, Object)] [status, value]
    #   status 가 :already_array / :ok 이면 value 는 정규화된 Array,
    #   그 밖이면 value 는 진단용 정보(예외 메시지·클래스명·파싱 결과)다.
    def call(raw)
      return [ :already_array, raw ] if raw.is_a?(Array)

      source = raw.to_s
      parsed =
        begin
          JSON.parse(source)
        rescue JSON::ParserError
          begin
            JSON.parse(inspect_to_json(source))
          rescue JSON::ParserError => e
            return [ :unparseable, e.message ]
          end
        end

      return [ :not_array, parsed.class.to_s ] unless parsed.is_a?(Array)
      return [ :bad_shape, parsed ] unless parsed.all? { |entry| faq_entry?(entry) }

      [ :ok, parsed ]
    end

    # 저장 형태 분류 — lint·migration 이 같은 어휘를 쓰도록 한 곳에 둔다.
    # 반환: :empty | :array_ok | :string_parseable | :string_broken | :string_other
    def classify(raw)
      return :empty if raw.nil?
      return raw.empty? ? :empty : :array_ok if raw.is_a?(Array)

      source = raw.to_s
      begin
        JSON.parse(source).is_a?(Array) ? :string_parseable : :string_other
      rescue JSON::ParserError
        # inspect 변환으로 살아나면 STRING_BROKEN (원래 JSON 이 아니었다는 뜻)
        status, = call(source)
        RECOVERABLE.include?(status) ? :string_broken : :string_other
      end
    end

    # 그 payload 안에 **저작된** FAQ 가 몇 건인가 (도달 가능한 건수와 구분된다).
    def authored_count(raw)
      status, value = call(raw)
      RECOVERABLE.include?(status) ? value.size : 0
    end

    # 복원 결과가 원문을 그대로 담고 있는지 — 변환이 내용을 바꾸지 않았음을 호출부가 증명할 수 있게 한다.
    def preserves_source?(raw, entries)
      source = raw.to_s
      entries.all? { |e| source.include?(e["question"]) && source.include?(e["answer"]) }
    end

    private

    def faq_entry?(entry)
      entry.is_a?(Hash) &&
        entry["question"].is_a?(String) && !entry["question"].empty? &&
        entry["answer"].is_a?(String)   && !entry["answer"].empty?
    end

    # Ruby `Hash#inspect` 문자열 → JSON 문자열.
    #
    # 문자열 리터럴 **밖에서만** `=>` 를 `:` 로, 단어경계 `nil` 을 `null` 로 바꾼다.
    # 답변 본문에 `=>` 가 들어 있어도 보존돼야 하므로 단순 gsub 를 쓰지 않는다.
    def inspect_to_json(source)
      out = +""
      index = 0
      inside_string = false
      length = source.length

      while index < length
        char = source[index]

        if inside_string
          if char == "\\"                      # escape 는 다음 문자와 한 쌍으로 통과시킨다
            out << char << (source[index + 1] || "")
            index += 2
            next
          end
          inside_string = false if char == '"'
          out << char
          index += 1
        elsif char == '"'
          inside_string = true
          out << char
          index += 1
        elsif char == "=" && source[index + 1] == ">"
          out << ":"
          index += 2
        elsif source[index, 3] == "nil" && !word_char?(source[index + 3])
          out << "null"
          index += 3
        else
          out << char
          index += 1
        end
      end

      out
    end

    def word_char?(char)
      char.present? && char.match?(/[A-Za-z0-9_]/)
    end
  end
end
