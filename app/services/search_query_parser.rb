# frozen_string_literal: true

# 검색 쿼리 파서 — 멀티워드 토큰 분리 + 동의어 확장
#
# 배경: silmu-search가 쿼리 전체를 단일 ILIKE 패턴으로 매칭해
#   - "지방계약법 수의계약" 류 멀티워드 쿼리가 AND 매칭되지 않음
#   - "성과급"·"명퇴" 등 구어/약어가 정식 행정용어 콘텐츠를 못 찾음
# 본 모듈이 쿼리를 공백으로 토큰 분리하고, 각 토큰을 동의어로 확장한
# "토큰별 변형 배열"을 반환한다. 원어는 항상 유지(순수 가산).
class SearchQueryParser
  # 동의어 단방향 매핑 — 양방향이 필요하면 양쪽 모두 기재.
  # 토큰(소문자)을 키로, 추가 변형 배열을 값으로 가진다.
  SYNONYMS = {
    "성과급" => [ "성과상여금" ],
    "성과상여금" => [ "성과급" ],
    "출장비" => [ "여비" ],
    "여비" => [ "출장비" ],
    "명퇴" => [ "명예퇴직" ],
    "mas" => [ "다수공급자계약" ],
    "다수공급자계약" => [ "단가계약" ],
    "제3자단가" => [ "단가계약" ],
    "관인" => [ "직인" ],
    "직인" => [ "관인" ],
    "수도광열비" => [ "공공요금" ],
    "회계감사" => [ "감사" ],
    "인건비" => [ "보수" ]
  }.freeze

  # 토큰 개수 상한 — 200자 truncate는 문자 수 제한일 뿐이라 토큰 폭발(바인드 파라미터·SQL 비대화) 방어선이 필요
  MAX_TOKENS = 8

  # 쿼리를 토큰별 변형 배열로 반환.
  # 예: "성과급 계산" → [["성과급", "성과상여금"], ["계산"]]
  # 빈/공백 쿼리는 [] 반환.
  def self.tokens(query)
    return [] if query.blank?

    query.split(/\s+/).first(MAX_TOKENS).filter_map do |raw|
      token = raw.strip
      next if token.empty?

      variants = [ token ]
      synonyms = SYNONYMS[token.downcase]
      variants.concat(synonyms) if synonyms
      variants.uniq
    end
  end
end
