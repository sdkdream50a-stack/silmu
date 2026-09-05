# frozen_string_literal: true

# P1.5 §13·§14 — Impact Graph.
#
# 변경된 법령 → ContentAuthorityLink → 영향 가능 콘텐츠 → 검토 태스크.
# **콘텐츠를 수정하지 않는다.** 태스크만 만든다.
module Authority
  class ImpactAnalyzer
    # 변경된 조문 목록을 machine_diff 에서 뽑아 DIRECT/INDIRECT 를 가른다.
    def analyze(change_event)
      links = ContentAuthorityLink.where(authority_document_id: change_event.authority_document_id)

      if links.empty?
        change_event.update!(impact_status: "NO_CONTENT_LINKED")
        return []
      end

      changed_articles = extract_changed_articles(change_event)
      tasks = links.map { |link| build_task(change_event, link, changed_articles) }.compact
      change_event.update!(impact_status: "ANALYZED")
      tasks
    end

    private

    def extract_changed_articles(event)
      sections = event.machine_diff["sections"] || {}
      (Array(sections["added"]) + Array(sections["removed"]) + Array(sections["modified"]))
        .map { |a| a.to_s.gsub(/\s+/, "") }.uniq
    end

    def build_task(event, link, changed_articles)
      impact_class, reason = classify(event, link, changed_articles)
      priority = priority_for(impact_class, link)

      task = AuthorityReviewTask.find_or_initialize_by(
        authority_change_event_id: event.id,
        affected_type: link.content_type,
        affected_id: link.content_id,
        affected_key: link.content_key
      )
      return task if task.persisted? # 이미 만들어진 태스크는 덮어쓰지 않는다

      task.assign_attributes(
        affected_label: label_for(link),
        impact_class: impact_class,
        impact_reason: reason,
        priority: priority,
        status: "OPEN"
      )
      task.save!
      task
    end

    # §14 — 확신할 수 없으면 UNKNOWN 으로 두고 사람에게 보낸다.
    def classify(event, link, changed_articles)
      if event.change_type == "REPEALED"
        return [ "DIRECT", "근거 법령이 폐지되었습니다. 대체 근거 확인이 필요합니다." ]
      end

      if changed_articles.any?
        linked = link.article_reference.to_s.gsub(/\s+/, "")
        if linked.present? && changed_articles.include?(linked)
          return [ "DIRECT", "이 콘텐츠가 근거로 삼는 #{link.article_reference} 가 직접 변경되었습니다." ]
        end
        if linked.present?
          return [ "INDIRECT", "같은 법령의 다른 조문(#{changed_articles.first(3).join(', ')})이 변경되었습니다. " \
                               "#{link.article_reference} 에 대한 영향은 확인이 필요합니다." ]
        end
        return [ "POSSIBLE", "법령 본문이 변경되었고 이 콘텐츠는 해당 법령을 근거로 합니다(조문 미지정)." ]
      end

      if event.change_type == "EFFECTIVE_DATE_CHANGED"
        return [ "POSSIBLE", "시행일이 변경되었습니다. 적용 시점 서술 확인이 필요합니다." ]
      end
      if event.change_type == "METADATA_CHANGED"
        return [ "POSSIBLE", "법령 메타데이터(#{event.diff_summary})가 변경되었습니다." ]
      end

      [ "UNKNOWN", "변경이 감지되었으나 영향 범위를 자동으로 판정할 수 없습니다. 사람 검토가 필요합니다." ]
    end

    # 우선순위 1 은 "도구·서식이 직접 영향" 에 예약한다 — 잘못된 값이 곧바로 기안으로 들어가는 경우다(§34·§35).
    # 그래서 일반 콘텐츠의 DIRECT 는 2 에서 시작하고, 도구·서식만 한 단계 올라간다.
    BASE_PRIORITY = { "DIRECT" => 2, "UNKNOWN" => 3, "INDIRECT" => 4, "POSSIBLE" => 4, "NO_IMPACT" => 5 }.freeze
    TOOL_LIKE = %w[Tool Template].freeze

    def priority_for(impact_class, link)
      base = BASE_PRIORITY.fetch(impact_class, 4)
      base -= 1 if TOOL_LIKE.include?(link.content_type)
      base.clamp(1, 5)
    end

    def label_for(link)
      rec = link.content_record
      return "#{link.content_type} / #{link.content_key}" if rec.nil?

      title = rec.try(:title) || rec.try(:name) || rec.try(:slug)
      "#{link.content_type} / #{title}"
    end
  end
end
