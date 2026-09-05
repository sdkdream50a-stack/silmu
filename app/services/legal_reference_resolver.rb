# frozen_string_literal: true

# P1-4 / §14~§16 — 법령 참조 문자열을 "검증 가능한 근거"로 승격한다.
#
# 목표: 이미 본문·legal_basis 에 존재하는 `지방계약법 시행령 제25조` 같은 텍스트를
#       사용자가 클릭해 원문을 확인할 수 있는 링크로 만든다.
#
# ⚠️ 절대 규칙 (§15 No Fabricated Legal URLs)
#   문자열에서 법령을 **확실하게 식별할 수 없으면 URL 을 만들지 않는다.**
#   "아마 이 법일 것"이라는 추론으로 링크를 생성하지 않는다.
#   → 허용 목록(KNOWN_LAWS)에 있는 법령만 HIGH confidence 로 해석하고, 그 외는 텍스트로 남긴다.
#
# URL 형식은 새로 발명하지 않는다. 이미 운영에서 쓰는 규약을 그대로 재사용한다:
#   SeoHelper#legislation_ref → "https://www.law.go.kr/법령/#{name.delete(' ')}"
class LegalReferenceResolver
  Reference = Struct.new(
    :raw, :law_name, :canonical_name, :articles, :official_url,
    :confidence, :resolution_source, keyword_init: true
  ) do
    def resolved? = official_url.present?
    def display_name = canonical_name.presence || law_name

    # 조문 표기 정리: 제N조 를 만나면 새 묶음을 시작하고, 항/호/목은 직전 조에 붙인다.
    #   ["제25조","제1항","제5호","제30조"] → "제25조 제1항 제5호, 제30조"
    def article_text
      groups = []
      Array(articles).each do |a|
        if a.match?(/\A제\d+조/) || groups.empty?
          groups << [ a ]
        else
          groups.last << a
        end
      end
      groups.map { |g| g.join(" ") }.join(", ")
    end

    def label
      [ display_name, article_text.presence ].compact.join(" ")
    end
  end

  LAW_URL_BASE = "https://www.law.go.kr/법령/"

  # ── HIGH confidence 허용 목록 ─────────────────────────────
  # 조건: 법제처 국가법령정보센터에 "법령" 으로 존재하고, 이름만으로 유일하게 식별되는 것.
  # 자치법규(조례·규칙)·기관 내부 지침·예규 별표는 여기에 넣지 않는다 — law.go.kr/법령 으로
  # 해석되지 않거나 기관마다 달라서 오링크가 된다.
  KNOWN_LAWS = {
    # 계약·조달
    "지방자치단체를 당사자로 하는 계약에 관한 법률" => "지방자치단체를 당사자로 하는 계약에 관한 법률",
    "지방계약법" => "지방자치단체를 당사자로 하는 계약에 관한 법률",
    "국가를 당사자로 하는 계약에 관한 법률" => "국가를 당사자로 하는 계약에 관한 법률",
    "국가계약법" => "국가를 당사자로 하는 계약에 관한 법률",
    "건설산업기본법" => "건설산업기본법",
    "전기공사업법" => "전기공사업법",
    "하도급거래 공정화에 관한 법률" => "하도급거래 공정화에 관한 법률",
    # 재정·회계
    "지방재정법" => "지방재정법",
    "지방회계법" => "지방회계법",
    "국가재정법" => "국가재정법",
    "국고금관리법" => "국고금 관리법",
    "회계관계직원 등의 책임에 관한 법률" => "회계관계직원 등의 책임에 관한 법률",
    # 인사·복무·보수
    "지방공무원법" => "지방공무원법",
    "국가공무원법" => "국가공무원법",
    "지방공무원 보수규정" => "지방공무원 보수규정",
    "지방공무원보수규정" => "지방공무원 보수규정",
    "공무원보수규정" => "공무원보수규정",
    "공무원 보수규정" => "공무원보수규정",
    "공무원수당 등에 관한 규정" => "공무원수당 등에 관한 규정",
    "지방공무원 수당 등에 관한 규정" => "지방공무원 수당 등에 관한 규정",
    "공무원 여비 규정" => "공무원 여비 규정",
    "공무원여비규정" => "공무원 여비 규정",
    "지방공무원 여비 규정" => "지방공무원 여비 규정",
    "지방공무원 복무규정" => "지방공무원 복무규정",
    "국가공무원 복무규정" => "국가공무원 복무규정",
    "지방공무원 임용령" => "지방공무원 임용령",
    # 재산·물품
    "공유재산 및 물품 관리법" => "공유재산 및 물품 관리법",
    "공유재산 및 물품관리법" => "공유재산 및 물품 관리법",
    "물품관리법" => "물품관리법",
    "국유재산법" => "국유재산법",
    # 교육
    "사립학교법" => "사립학교법",
    "초·중등교육법" => "초·중등교육법",
    "초중등교육법" => "초·중등교육법",
    "유아교육법" => "유아교육법",
    "교육공무원법" => "교육공무원법",
    "지방교육자치에 관한 법률" => "지방교육자치에 관한 법률",
    "지방교육재정교부금법" => "지방교육재정교부금법",
    # 감사·청렴·절차
    "공공감사에 관한 법률" => "공공감사에 관한 법률",
    "감사원법" => "감사원법",
    "부정청탁 및 금품등 수수의 금지에 관한 법률" => "부정청탁 및 금품등 수수의 금지에 관한 법률",
    "공직자의 이해충돌 방지법" => "공직자의 이해충돌 방지법",
    "행정절차법" => "행정절차법",
    "질서위반행위규제법" => "질서위반행위규제법",
    # 정보·기록
    "공공기관의 정보공개에 관한 법률" => "공공기관의 정보공개에 관한 법률",
    "개인정보 보호법" => "개인정보 보호법",
    "공공기록물 관리에 관한 법률" => "공공기록물 관리에 관한 법률",
    # 보조금
    "지방자치단체 보조금 관리에 관한 법률" => "지방자치단체 보조금 관리에 관한 법률",
    "보조금 관리에 관한 법률" => "보조금 관리에 관한 법률",
    # 안전·기타
    "산업안전보건법" => "산업안전보건법",
    "중대재해 처벌 등에 관한 법률" => "중대재해 처벌 등에 관한 법률",
    "건축법" => "건축법",
    "형법" => "형법",
    "지방자치법" => "지방자치법"
  }.freeze

  # 하위 법령 접미어 — 상위 법령명에 붙여 해석한다.
  SUBORDINATE_SUFFIXES = [ "시행령", "시행규칙" ].freeze

  # 대용어(anaphora): 앞에서 언급한 법을 가리킨다.
  ANAPHORA_RE = /\A(?:같은\s?법|동법|위\s?법)\s*(#{SUBORDINATE_SUFFIXES.join('|')})?\z/
  BARE_SUBORDINATE_RE = /\A(#{SUBORDINATE_SUFFIXES.join('|')})\z/

  # 조문 표기: 제25조, 제25조의3, 제1항, 제5호, 목
  ARTICLE_RE = /제\s?\d+(?:조|항|호|목)(?:의\s?\d+)?/

  class << self
    # 문자열 하나를 Reference 배열로 해석한다.
    def resolve(text)
      new(text).references
    end

    # 링크 가능한 참조만
    def resolve_linkable(text)
      resolve(text).select(&:resolved?)
    end

    def known_law?(name)
      KNOWN_LAWS.key?(normalize(name))
    end

    def canonical_for(name)
      KNOWN_LAWS[normalize(name)]
    end

    def official_url_for(canonical)
      return nil if canonical.blank?

      "#{LAW_URL_BASE}#{canonical.delete(' ')}"
    end

    def normalize(name)
      name.to_s.gsub(/[「」『』]/, "").gsub(/\s+/, " ").strip
    end
  end

  def initialize(text)
    @text = text.to_s
  end

  def references
    @references ||= build_references
  end

  private

  attr_reader :text

  # 쉼표·슬래시로 분리하되 **괄호 안은 자르지 않는다.**
  # (legal_basis 에 `(재무기획관-40945, 2020.12.31.)` 같은 표기가 실제로 존재한다)
  def segments
    out = []
    buf = +""
    depth = 0
    text.each_char do |ch|
      case ch
      when "(", "（" then depth += 1; buf << ch
      when ")", "）" then depth -= 1 if depth.positive?
                        buf << ch
      when ",", "/", "·"
        if depth.zero? && ch != "·"
          out << buf; buf = +""
        else
          buf << ch
        end
      else
        buf << ch
      end
    end
    out << buf
    out.map { |s| s.gsub(/[「」『』]/, "").strip }.reject(&:blank?)
  end

  def build_references
    base_law = nil          # 직전에 확정된 상위 법령 (대용어 해석용)
    base_law_count = 0      # 문자열 전체에서 확정된 상위 법령 수
    refs = []

    segments.each do |seg|
      articles = seg.scan(ARTICLE_RE).map { |a| a.gsub(/\s+/, "") }
      name = seg.sub(/\s*제\s?\d+.*\z/, "").strip
      name = name.sub(/\((?:[^)]*)\)\z/, "").strip   # 꼬리 괄호 주석 제거

      # ── 조문만 있는 세그먼트: 직전 참조에 조문을 덧붙인다 ──
      if name.blank?
        refs.last&.articles&.concat(articles) if articles.any? && refs.last
        next
      end

      normalized = self.class.normalize(name)
      law_name = normalized
      canonical = nil
      resolution_source = nil
      confidence = "LOW"

      if (m = normalized.match(ANAPHORA_RE))
        # "같은 법", "같은법 시행령" → 직전 상위 법령 상속
        if base_law.present?
          canonical = m[1] ? "#{base_law} #{m[1]}" : base_law
          law_name = canonical
          # 문자열 안에 상위 법령이 정확히 하나일 때만 확실하다.
          confidence = base_law_count == 1 ? "HIGH" : "MEDIUM"
          resolution_source = "anaphora_from_base_law"
        else
          confidence = "LOW"
          resolution_source = "anaphora_unresolved"
        end
      elsif normalized.match?(BARE_SUBORDINATE_RE)
        # "시행령", "시행규칙" 단독
        if base_law.present?
          canonical = "#{base_law} #{normalized}"
          law_name = canonical
          confidence = base_law_count == 1 ? "HIGH" : "MEDIUM"
          resolution_source = "bare_subordinate_from_base_law"
        else
          confidence = "LOW"
          resolution_source = "bare_subordinate_unresolved"
        end
      else
        # "지방계약법 시행령" 처럼 상위법 + 접미어가 붙은 형태 분해
        suffix = SUBORDINATE_SUFFIXES.find { |sfx| normalized.end_with?(" #{sfx}", sfx) }
        head = suffix ? normalized.sub(/\s*#{suffix}\z/, "").strip : normalized

        if self.class.known_law?(head)
          canonical_head = self.class.canonical_for(head)
          base_law = canonical_head
          base_law_count += 1
          canonical = suffix ? "#{canonical_head} #{suffix}" : canonical_head
          law_name = canonical
          confidence = "HIGH"
          resolution_source = suffix ? "known_law_with_suffix" : "known_law"
        else
          # 허용 목록에 없다 → 자치법규·내부지침·예규 등. 링크하지 않는다.
          confidence = "LOW"
          resolution_source = "not_in_allowlist"
        end
      end

      url = confidence == "HIGH" ? self.class.official_url_for(canonical) : nil

      refs << Reference.new(
        raw: seg,
        law_name: law_name,
        canonical_name: canonical,
        articles: articles,
        official_url: url,
        confidence: confidence,
        resolution_source: resolution_source
      )
    end

    refs
  end
end
