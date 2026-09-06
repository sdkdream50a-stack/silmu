# frozen_string_literal: true

# 검색 쿼리 파서 — 멀티워드 토큰 분리 + 동의어 확장
#
# 배경: silmu-search가 쿼리 전체를 단일 ILIKE 패턴으로 매칭해
#   - "지방계약법 수의계약" 류 멀티워드 쿼리가 AND 매칭되지 않음
#   - "성과급"·"명퇴" 등 구어/약어가 정식 행정용어 콘텐츠를 못 찾음
# 본 모듈이 쿼리를 공백으로 토큰 분리하고, 각 토큰을 동의어로 확장한
# "토큰별 변형 배열"을 반환한다. 원어는 항상 유지(순수 가산).
#
# P1.6: 자연어 질문("병가 며칠 쓰면 진단서 내야 하나요")이 결과 0건이 되던 문제를 고친다.
# Topic.search_multiple 이 전 토큰 AND 매칭이라 조사·어미·의문사가 한 개라도 섞이면
# 어떤 필드에도 없어서 AND가 즉시 깨졌다. 여기서 두 가지를 더 한다.
#   1) STOPWORDS — 조사·어미·의문사를 토큰에서 제거 (순수 노이즈)
#   2) 조사 분리   — "계약을" 에서 "계약" 을 **추가 변형**으로 넣는다 (대체 아님, 순수 가산)
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
    "인건비" => [ "보수" ],
    # P1.6 — 사용자가 정식 행정용어를 모를 때 쓰는 구어 (고가치분만. 대량 생성 금지)
    #
    # ⚠️ **연상어를 동의어로 넣지 말 것.** 처음에 "진단서"→"병가", "견적"→"수의계약" 을 넣었더니
    #    "병가 진단서" 검색에서 "병가는 연 60일까지" FAQ 가 "바로 답"으로 올라왔다.
    #    질문이 다른데 답이 확신 있게 뜨는 것이 가장 나쁜 실패다. 같은 것을 가리키는 말만 넣는다.
    # ⚠️ 매칭이 ILIKE 부분일치라 "연가"→"연가보상비" 같은 포함관계 매핑은 중복이다(이미 매칭된다).
    "연차" => [ "연가" ],
    # "차비"→"여비" 는 뺐다(P1.6 독립검증). 여비는 숙박비·식비까지 포함하는 상위 범주라
    # "차비 지급 기준" 이 "숙박비 지급 기준" 을 "바로 답"으로 올렸다 — 위 ⚠️ 규칙 위반이다.
    "차비" => [ "운임" ],
    "견적" => [ "견적서" ],
    "1인견적" => [ "1인 견적" ],
    "공개청구" => [ "정보공개" ]
  }.freeze

  # 토큰 개수 상한 — 200자 truncate는 문자 수 제한일 뿐이라 토큰 폭발(바인드 파라미터·SQL 비대화) 방어선이 필요
  MAX_TOKENS = 8

  # 조사·어미·의문사 — 콘텐츠 어느 필드에도 등장하지 않는 순수 노이즈.
  # 토큰 "전체"가 여기 해당할 때만 제거한다(부분 문자열 제거 아님).
  STOPWORDS = %w[
    하나요 하나 한가요 인가요 되나요 될까요 있나요 없나요
    가능한가요 가능한지 해야 해도 하면 쓰면 내야 받나요 지급하나 지급하나요
    답변은 맡았어요 맡았을 맡았는데
    며칠 얼마 언제 어디 누가 무엇 어떻게 어떤
    안에 이내 까지 부터 에서 에게 한테 으로
    좀 그냥 제가 저는 우리 관련 경우 그리고 또는
  ].freeze

  # 분리 대상 조사 — 긴 것부터 검사한다(“으로” 가 “로” 보다 먼저).
  PARTICLES = %w[
    으로 에서 에게 한테 까지 부터 이나 라도 처럼 보다 마다 조차 밖에 에는 에도 로는
    을 를 이 가 은 는 에 의 로 와 과 도 만 랑 께
  ].freeze

  # 조사를 뗀 어간의 최소 길이 — "자가"→"자", "국가"→"국" 같은 오분리를 막는다.
  MIN_STEM = 2

  # 쿼리를 토큰별 변형 배열로 반환.
  # 예: "성과급 계산"      → [["성과급", "성과상여금"], ["계산"]]
  #     "처음 계약을 맡았어요" → [["처음"], ["계약을", "계약"]]   ("맡았어요" = stopword)
  # 빈/공백 쿼리는 [] 반환.
  # 토큰이 전부 stopword 면 원본 토큰을 그대로 쓴다(빈 결과 방지).
  def self.tokens(query)
    return [] if query.blank?

    raw_tokens = query.split(/\s+/).filter_map { |raw| normalize(raw).presence }.first(MAX_TOKENS)
    return [] if raw_tokens.empty?

    content = raw_tokens.reject { |t| STOPWORDS.include?(t.downcase) }
    # 전부 조사·어미뿐이면 걸러내지 않는다 — 거를 게 없는 것과 다 걸러진 것을 구분해야 한다.
    content = raw_tokens if content.empty?

    content.map { |token| variants_for(token) }
  end

  # 토큰 하나의 변형 배열 — 원어 + 동의어 + 조사 분리형. 전부 가산이며 원어는 항상 남는다.
  def self.variants_for(token)
    variants = [ token ]
    synonyms = SYNONYMS[token.downcase]
    variants.concat(synonyms) if synonyms

    stem = strip_particle(token)
    if stem
      variants << stem
      stem_synonyms = SYNONYMS[stem.downcase]
      variants.concat(stem_synonyms) if stem_synonyms
    end

    variants.uniq
  end

  # 토큰 끝의 조사를 뗀 어간을 반환. 뗄 수 없으면 nil.
  # PARTICLES 는 긴 것부터 정렬돼 있고, **처음 일치한 조사에서 판정을 끝낸다.**
  # 계속 짧은 조사를 시도하면 "돈으로" 가 "으로"(어간 "돈", 1자라 기각) 실패 후
  # "로" 로 다시 걸려 "돈으" 같은 쓰레기 어간을 만든다.
  def self.strip_particle(token)
    particle = PARTICLES.find { |p| token.end_with?(p) }
    return nil unless particle

    stem = token[0...-particle.length]
    stem.length >= MIN_STEM ? stem : nil
  end

  # 검색에 무의미한 꼬리 문장부호를 제거한다("하나요?" 가 stopword 로 안 걸리는 문제).
  def self.normalize(raw)
    raw.strip.gsub(/[?!.,"'`~;:]+\z/, "")
  end

  private_class_method :variants_for, :strip_particle, :normalize
end
