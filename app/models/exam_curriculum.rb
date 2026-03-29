# 공공조달관리사 표준교재 4권 기반 커리큘럼 데이터
# 한국조달연구원 공공조달관리사 표준교재 (2026.01 기준)
# 각 권 데이터는 app/models/exam_curriculum/subject{1..4}.rb에 분리 보관
module ExamCurriculum
  SUBJECTS = [
    Subject1::DATA,
    Subject2::DATA,
    Subject3::DATA,
    Subject4::DATA
  ].freeze

  # 챕터 키→제목 맵 (메모이제이션: 매 호출마다 재구축 방지)
  # { "1-1" => { title: ..., subject_number: ... } }
  CHAPTER_MAP = begin
    result = {}
    SUBJECTS.each do |s|
      s[:chapters].each do |c|
        result["#{s[:id]}-#{c[:number]}"] = { title: c[:title], subject_number: s[:number] }
      end
    end
    result.freeze
  end

  def self.chapter_map
    CHAPTER_MAP
  end

  # 챕터별 관련 토픽 슬러그 맵 { "subject_id-chapter_num" => ["slug1", "slug2"] }
  CHAPTER_TOPIC_SLUGS = begin
    result = {}
    SUBJECTS.each do |s|
      s[:chapters].each do |c|
        slugs = c[:related_topic_slugs]
        next if slugs.nil? || slugs.empty?
        result["#{s[:id]}-#{c[:number]}"] = slugs
      end
    end
    result.freeze
  end

  def self.chapter_topic_slugs
    CHAPTER_TOPIC_SLUGS
  end

  # 과목 인덱스 (메모이제이션: find 호출마다 배열 순회 방지)
  SUBJECTS_BY_ID = SUBJECTS.index_by { |s| s[:id] }.freeze

  # 챕터 인덱스 { "subject_id-chapter_number" => chapter_hash }
  CHAPTERS_INDEX = begin
    result = {}
    SUBJECTS.each do |s|
      s[:chapters].each do |c|
        result["#{s[:id]}-#{c[:number]}"] = c
      end
    end
    result.freeze
  end

  # 과목 찾기 — O(1) 해시 조회
  def self.find_subject(id)
    SUBJECTS_BY_ID[id.to_i]
  end

  # 챕터 찾기 — O(1) 해시 조회
  def self.find_chapter(subject_id, chapter_number)
    CHAPTERS_INDEX["#{subject_id.to_i}-#{chapter_number.to_i}"]
  end

  # 전체 키워드 목록 (메모이제이션: 3중 루프 재구축 방지)
  ALL_KEYWORDS = begin
    result = []
    SUBJECTS.each do |subject|
      subject[:chapters].each do |chapter|
        chapter[:keywords].each do |keyword|
          result << {
            keyword: keyword,
            subject_id: subject[:id],
            subject_title: subject[:title],
            subject_number: subject[:number],
            subject_color: subject[:color],
            chapter_number: chapter[:number],
            chapter_title: chapter[:title]
          }
        end
      end
    end
    result.freeze
  end

  def self.all_keywords
    ALL_KEYWORDS
  end

  # 키워드 + ExamKeywordDetails 통합 데이터 (메모이제이션: 매 요청마다 merge 제거)
  ALL_KEYWORDS_WITH_DETAILS = ALL_KEYWORDS.map do |kw|
    detail = ExamKeywordDetails.find(kw[:keyword])
    kw.merge(
      definition: detail&.dig(:definition),
      example: detail&.dig(:example),
      quiz_ids: detail&.dig(:quiz_ids) || []
    )
  end.freeze

  def self.all_keywords_with_details
    ALL_KEYWORDS_WITH_DETAILS
  end

  # 과목별 색상 Tailwind 클래스
  SUBJECT_COLORS = {
    "emerald" => {
      bg: "bg-emerald-50",
      bg_dark: "bg-emerald-600",
      border: "border-emerald-200",
      text: "text-emerald-700",
      text_dark: "text-emerald-600",
      badge: "bg-emerald-100 text-emerald-800",
      hover_border: "hover:border-emerald-400",
      icon_bg: "bg-emerald-100",
      progress: "bg-emerald-500",
      accent_border: "border-emerald-600",
      btn_gradient: "from-emerald-700 to-emerald-500",
      shadow_color: "shadow-emerald-600/20"
    },
    "blue" => {
      bg: "bg-blue-50",
      bg_dark: "bg-blue-600",
      border: "border-blue-200",
      text: "text-blue-700",
      text_dark: "text-blue-600",
      badge: "bg-blue-100 text-blue-800",
      hover_border: "hover:border-blue-400",
      icon_bg: "bg-blue-100",
      progress: "bg-blue-500",
      accent_border: "border-blue-600",
      btn_gradient: "from-blue-700 to-blue-500",
      shadow_color: "shadow-blue-600/20"
    },
    "violet" => {
      bg: "bg-violet-50",
      bg_dark: "bg-violet-600",
      border: "border-violet-200",
      text: "text-violet-700",
      text_dark: "text-violet-600",
      badge: "bg-violet-100 text-violet-800",
      hover_border: "hover:border-violet-400",
      icon_bg: "bg-violet-100",
      progress: "bg-violet-500",
      accent_border: "border-violet-600",
      btn_gradient: "from-violet-700 to-violet-500",
      shadow_color: "shadow-violet-600/20"
    },
    "rose" => {
      bg: "bg-rose-50",
      bg_dark: "bg-rose-600",
      border: "border-rose-200",
      text: "text-rose-700",
      text_dark: "text-rose-600",
      badge: "bg-rose-100 text-rose-800",
      hover_border: "hover:border-rose-400",
      icon_bg: "bg-rose-100",
      progress: "bg-rose-500",
      accent_border: "border-rose-600",
      btn_gradient: "from-rose-700 to-rose-500",
      shadow_color: "shadow-rose-600/20"
    }
  }.freeze

  def self.colors(color_name)
    SUBJECT_COLORS[color_name] || SUBJECT_COLORS["blue"]
  end
end
