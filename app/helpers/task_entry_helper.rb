# frozen_string_literal: true

# P1.6 §24·§26 — 업무(task) 진입점.
#
# 원칙: 사용자는 "법령가이드/감사사례"가 아니라 "계약·조달", "복무" 같은 **업무**로 생각한다.
# 내부 taxonomy(topic.category / guide.category / audit_case.category)는 그대로 두고
# 그 위에 업무 라벨을 씌운다 — URL·SEO 자산은 건드리지 않는다.
#
# 노출 판정은 **런타임 count** 다. 개발 DB 에서 센 수치를 코드에 박으면 운영에서 틀린다
# (운영 Topics 114 vs dev 92). 콘텐츠가 생기면 카드가 저절로 나타나고, 없으면 저절로 사라진다.
module TaskEntryHelper
  # 카드 1장 노출 최소 콘텐츠 수. 1~2건짜리 칸은 클릭했을 때 실망만 준다.
  MIN_COVERAGE = 3

  # Tailwind JIT 는 소스에 리터럴로 있는 클래스만 만든다 → 색을 동적으로 조립하지 않는다.
  TASK_ENTRIES = [
    { key: "contract", label: "계약·조달", icon: "gavel",
      hint: "수의계약·입찰·검수·대금지급",
      icon_class: "bg-indigo-50 text-indigo-600",
      topic_categories: %w[contract], guide_categories: [ "계약" ],
      guide_series: [ "수의계약_완전정복", "공사계약_완전정복", "입찰_완전정복" ],
      audit_categories: [ "수의계약", "입찰", "계약체결", "계약이행", "대금지급", "하도급", "검수/검사" ],
      path_helper: [ :topics_category_path, "contract" ] },

    { key: "budget", label: "예산·회계", icon: "account_balance",
      hint: "편성·집행·이월·전용·결산",
      icon_class: "bg-blue-50 text-blue-600",
      topic_categories: %w[budget expense], guide_categories: [ "예산" ],
      guide_series: [ "예산편성_완전정복", "예산집행_완전정복" ],
      audit_categories: [ "예산", "회계" ],
      path_helper: [ :topics_category_path, "budget" ] },

    { key: "duty", label: "복무", icon: "badge",
      hint: "휴가·병가·출장·겸직",
      icon_class: "bg-orange-50 text-orange-600",
      topic_categories: %w[duty], guide_categories: [ "복무" ],
      guide_series: [ "인사복무_완전정복" ], audit_categories: [],
      path_helper: [ :topics_category_path, "duty" ] },

    { key: "salary", label: "보수·수당", icon: "payments",
      hint: "봉급·초과근무·성과상여금·연가보상비",
      icon_class: "bg-emerald-50 text-emerald-600",
      topic_categories: %w[salary], guide_categories: [ "인사" ],
      guide_series: [], audit_categories: [],
      path_helper: [ :topics_category_path, "salary" ] },

    { key: "travel", label: "여비·출장", icon: "flight_takeoff",
      hint: "운임·일비·숙박비·정산",
      icon_class: "bg-rose-50 text-rose-600",
      topic_categories: %w[travel], guide_categories: [],
      guide_series: [ "출장여비_완전정복" ], audit_categories: [],
      path_helper: [ :topics_category_path, "travel" ] },

    { key: "subsidy", label: "보조금", icon: "volunteer_activism",
      hint: "교부·집행·정산·반환",
      icon_class: "bg-violet-50 text-violet-600",
      topic_categories: %w[subsidy], guide_categories: [],
      guide_series: [ "지방보조금_완전정복" ], audit_categories: [],
      path_helper: [ :topics_category_path, "subsidy" ] },

    { key: "property", label: "재산·물품", icon: "domain",
      hint: "취득·관리·처분",
      icon_class: "bg-teal-50 text-teal-600",
      topic_categories: %w[property], guide_categories: [],
      guide_series: [], audit_categories: [],
      path_helper: [ :topics_category_path, "property" ] },

    { key: "audit", label: "감사·청렴", icon: "policy",
      hint: "자주 지적되는 것부터 확인",
      icon_class: "bg-amber-50 text-amber-600",
      topic_categories: [], guide_categories: [],
      guide_series: [], audit_categories: :all,
      path_helper: [ :audit_cases_path ] },

    { key: "newcomer", label: "처음 맡은 업무", icon: "school",
      hint: "계약·예산·지출·급여를 처음 맡았다면",
      icon_class: "bg-slate-100 text-slate-600",
      topic_categories: [], guide_categories: [],
      guide_series: :any_series, audit_categories: [],
      path_helper: [ :onboarding_path ] }
  ].freeze

  # 커버리지가 MIN_COVERAGE 이상인 업무 카드만 반환한다.
  def task_entries
    counts = Rails.cache.fetch("home/task_entry_counts/v1", expires_in: 1.hour) { task_entry_counts }

    TASK_ENTRIES.filter_map do |entry|
      count = counts[entry[:key]].to_i
      next if count < MIN_COVERAGE

      entry.merge(count: count)
    end
  end

  # 업무별 콘텐츠 수 — topic + guide + audit_case 합산. 그룹 카운트 3회로 끝낸다.
  def task_entry_counts
    topic_by_cat  = Topic.published.group(:category).count
    guide_by_cat  = Guide.published.group(:category).count
    guide_by_ser  = Guide.published.where.not(series: nil).group(:series).count
    audit_by_cat  = AuditCase.published.group(:category).count
    audit_total   = audit_by_cat.values.sum
    series_total  = guide_by_ser.values.sum

    TASK_ENTRIES.index_with do |entry|
      n  = entry[:topic_categories].sum { |c| topic_by_cat[c].to_i }
      n += entry[:guide_categories].sum { |c| guide_by_cat[c].to_i }
      n += case entry[:guide_series]
           when :any_series then series_total
           else Array(entry[:guide_series]).sum { |s| guide_by_ser[s].to_i }
      end
      n += entry[:audit_categories] == :all ? audit_total : Array(entry[:audit_categories]).sum { |c| audit_by_cat[c].to_i }
      n
    end.transform_keys { |entry| entry[:key] }
  end
end
