# frozen_string_literal: true

# 법령명 약칭 → 정식 명칭 해석기
#
# 출처: korean-law-mcp v3.5.4 (chrisryugj/korean-law-mcp, MIT)
#       src/lib/search-normalizer.ts 의 LAW_ALIAS_ENTRIES + resolveLawAlias
#       src/lib/law-search.ts 의 scoreLawRelevance 포팅
#
# 배경: 법제처 lawSearch API는 부분 문자열 매칭 특성이 있어
#   - "산안법" 같은 약칭은 매칭 실패
#   - "민법" 검색 시 "난민법"이 먼저 잡히는 오매칭 발생
# 본 모듈이 LawApiService.search_law 진입 시점에 약칭/오타를 정식명으로
# 치환하고, 결과 후보 다수일 때 관련도 점수로 재정렬한다.
class LawAliasResolver
  Resolution = Struct.new(:canonical, :matched_alias, :alternatives, keyword_init: true)

  # 기본 자형 오타 보정 (한글 음절 1글자 매핑)
  BASIC_CHAR_MAP = {
    "벚" => "법", "벆" => "법", "벋" => "법", "뻡" => "법",
    "볍" => "법", "뱝" => "법", "셰" => "세", "쉐" => "세",
    "괸" => "관", "곽" => "관", "엄" => "업", "얼" => "업"
  }.freeze
  BASIC_CHAR_RE = Regexp.new("[#{BASIC_CHAR_MAP.keys.join}]").freeze

  # 약칭 사전 (52종) — canonical: 정식명, aliases: 약칭/오타, alternatives: 함께 검토 권장
  LAW_ALIASES = [
    { canonical: "대한민국헌법", aliases: %w[헌법 헌\ 법] },
    { canonical: "관세법", aliases: ["관세벚", "관세요", "관세 볍", "관세 볍률"] },
    { canonical: "자유무역협정의 이행을 위한 관세법의 특례에 관한 법률",
      aliases: ["fta특례법", "fta 특례법", "fta 특례", "fta특례", "에프티에이특례법"],
      alternatives: ["관세법", "관세법 시행령", "관세법 시행규칙"] },
    { canonical: "화학물질관리법",
      aliases: ["화관법", "화관 법", "화학물질 관리법"],
      alternatives: ["화학물질관리법 시행령", "화학물질관리법 시행규칙"] },
    { canonical: "행정기본법",
      aliases: ["행정법", "행정 법"],
      alternatives: ["행정절차법", "행정조사기본법", "행정규제기본법"] },
    { canonical: "대외무역법",
      aliases: ["무역법", "원산지 사후판정", "원산지법"],
      alternatives: ["원산지표시법", "관세법"] },
    { canonical: "원산지표시법",
      aliases: ["원산지 표시법", "원산지표시"],
      alternatives: ["대외무역법", "관세법"] },
    { canonical: "관세법 시행령", aliases: %w[관시령 관세시행령 관세법시행령] },
    { canonical: "관세법 시행규칙", aliases: %w[관시규 관세시행규칙 관세법시행규칙] },
    { canonical: "지방공무원법",
      aliases: ["지방공무원", "지공법", "지방공무원 법"],
      alternatives: ["지방공무원 임용령", "지방공무원 보수규정"] },
    { canonical: "지방공무원 임용령", aliases: %w[지방공무원임용령 지공임용령] },
    { canonical: "지방공무원 보수규정", aliases: %w[지방공무원보수규정 지공보수규정] },
    { canonical: "산업안전보건법",
      aliases: %w[산안법],
      alternatives: ["산업안전보건법 시행령", "산업안전보건법 시행규칙",
                     "산업안전보건기준에 관한 규칙"] },
    { canonical: "산업안전보건기준에 관한 규칙",
      aliases: %w[산안기준규칙 안전보건규칙 산업안전보건규칙 산안규칙 안전보건기준규칙],
      alternatives: ["산업안전보건법", "산업안전보건법 시행령"] },
    { canonical: "중대재해 처벌 등에 관한 법률",
      aliases: %w[중대재해처벌법 중처법 중대재해법],
      alternatives: ["산업안전보건법"] },
    { canonical: "근로기준법", aliases: %w[근기법 근로법] },
    { canonical: "남녀고용평등과 일ㆍ가정 양립 지원에 관한 법률",
      aliases: %w[남녀고용평등법 고평법] },
    { canonical: "개인정보 보호법", aliases: %w[개보법 개인정보법 개인정보보호법] },
    { canonical: "정보통신망 이용촉진 및 정보보호 등에 관한 법률",
      aliases: %w[정보통신망법 정통망법] },
    { canonical: "부정청탁 및 금품등 수수의 금지에 관한 법률",
      aliases: %w[청탁금지법 김영란법] },
    { canonical: "공직자의 이해충돌 방지법",
      aliases: %w[이해충돌방지법 공직자이해충돌방지법] },
    { canonical: "국가를 당사자로 하는 계약에 관한 법률",
      aliases: %w[국가계약법],
      alternatives: ["국가를 당사자로 하는 계약에 관한 법률 시행령"] },
    { canonical: "지방자치단체를 당사자로 하는 계약에 관한 법률",
      aliases: %w[지방계약법],
      alternatives: ["지방자치단체를 당사자로 하는 계약에 관한 법률 시행령"] },
    { canonical: "공공기관의 정보공개에 관한 법률", aliases: %w[정보공개법] },
    { canonical: "부동산 거래신고 등에 관한 법률", aliases: %w[부동산거래신고법 부거법] },
    { canonical: "주택임대차보호법", aliases: %w[주임법] },
    { canonical: "상가건물 임대차보호법", aliases: %w[상임법 상가임대차법] },
    { canonical: "소방시설 설치 및 관리에 관한 법률", aliases: %w[소방시설법] },
    { canonical: "국세기본법", aliases: %w[국기법] },
    { canonical: "부가가치세법", aliases: %w[부가세법] },
    { canonical: "독점규제 및 공정거래에 관한 법률",
      aliases: %w[공정거래법 공거법 독점규제법],
      alternatives: ["독점규제 및 공정거래에 관한 법률 시행령"] },
    { canonical: "하도급거래 공정화에 관한 법률", aliases: %w[하도급법] },
    { canonical: "약관의 규제에 관한 법률", aliases: %w[약관법 약관규제법] },
    { canonical: "표시ㆍ광고의 공정화에 관한 법률", aliases: %w[표시광고법] },
    { canonical: "가맹사업거래의 공정화에 관한 법률", aliases: %w[가맹사업법 가맹법] },
    { canonical: "전자상거래 등에서의 소비자보호에 관한 법률", aliases: %w[전자상거래법 전상법] },
    { canonical: "신용정보의 이용 및 보호에 관한 법률", aliases: %w[신용정보법 신정법] },
    { canonical: "자본시장과 금융투자업에 관한 법률",
      aliases: %w[자본시장법 자시법],
      alternatives: ["자본시장과 금융투자업에 관한 법률 시행령"] },
    { canonical: "특정 금융거래정보의 보고 및 이용 등에 관한 법률", aliases: %w[특정금융정보법 특금법] },
    { canonical: "전자금융거래법", aliases: %w[전금법] },
    { canonical: "국토의 계획 및 이용에 관한 법률",
      aliases: %w[국토계획법 국계법 국토이용법],
      alternatives: ["국토의 계획 및 이용에 관한 법률 시행령"] },
    { canonical: "도시 및 주거환경정비법", aliases: %w[도시정비법 도정법] },
    { canonical: "감염병의 예방 및 관리에 관한 법률", aliases: %w[감염병예방법 감염병법] },
    { canonical: "대기환경보전법", aliases: %w[대기환경법 대기법] },
    { canonical: "여객자동차 운수사업법", aliases: %w[여객운수법 여객자동차법] },
    { canonical: "화물자동차 운수사업법", aliases: %w[화물운수법 화운법] },
    { canonical: "민사소송법", aliases: %w[민소법] },
    { canonical: "형사소송법", aliases: %w[형소법] },
    { canonical: "민사집행법", aliases: %w[민집법] },
    { canonical: "국민건강보험법", aliases: %w[국건법 건보법] },
    { canonical: "산업재해보상보험법", aliases: %w[산재보험법 산재법] },
    { canonical: "고용보험법", aliases: %w[고보법] },
    { canonical: "전기통신사업법", aliases: %w[전기통신법 전사법] }
  ].freeze

  class << self
    # 입력 법령명을 정식 명칭으로 해석한다.
    # 약칭 매칭 실패 시 입력값(오타 보정만 적용)을 그대로 canonical로 반환.
    #
    # @param law_name [String]
    # @return [Resolution]
    def resolve(law_name)
      key = normalize_key(law_name)
      entry = lookup[key]

      if entry
        matched = entry[:aliases].find { |a| normalize_key(a) == key }
        Resolution.new(
          canonical: entry[:canonical],
          matched_alias: matched,
          alternatives: entry[:alternatives] || []
        )
      else
        Resolution.new(
          canonical: normalize_basic_typos(law_name.to_s).strip,
          matched_alias: nil,
          alternatives: []
        )
      end
    end

    # 검색 결과 후보 다수일 때 쿼리 관련도로 정렬용 점수 산출.
    # 높을수록 관련도 ↑. (정확 매칭 100, 부분포함 80, 단어 매칭 10/단어, 법률 우선 +5)
    def relevance_score(law_name, query)
      score = 0
      score += 100 if query.to_s.include?(law_name.to_s)
      compact_query = query.to_s.gsub(/\s+/, "")
      score += 80 if law_name.to_s.include?(compact_query) && compact_query.length.positive?
      query_words(query).each { |w| score += 10 if law_name.to_s.include?(w) }
      score += 5 unless law_name.to_s.match?(/시행령|시행규칙/)
      score
    end

    private

    def lookup
      @lookup ||= LAW_ALIASES.each_with_object({}) do |entry, h|
        [entry[:canonical], *entry[:aliases]].each do |key|
          h[normalize_key(key)] = entry
        end
      end.freeze
    end

    def normalize_key(value)
      normalize_basic_typos(value.to_s)
        .downcase
        .gsub(/\s+/, "")
        .gsub(/[·•]/, "")
    end

    def normalize_basic_typos(value)
      value.to_s.gsub(BASIC_CHAR_RE) { |c| BASIC_CHAR_MAP[c] || c }
    end

    def query_words(query)
      query.to_s.split(/\s+/).reject(&:empty?)
    end
  end
end
