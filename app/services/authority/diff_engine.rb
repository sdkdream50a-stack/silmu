# frozen_string_literal: true

# P1.5 §20 — diff.
# 처음부터 완벽한 semantic diff 를 목표로 하지 않는다. 단계적으로 올린다.
#   Level 1 document hash
#   Level 2 metadata (개정일·시행일·제목·문서번호)
#   Level 3 조문/section    ← 구현
#   Level 4 paragraph       ← 설계만
module Authority
  class DiffEngine
    # 사용자에게 의미가 있는 메타데이터 필드만 비교한다.
    META_FIELDS = {
      title: "법령명",
      korean_type: "법령구분",
      agency: "소관부처",
      promulgated_on: "공포일자",
      revision_number: "공포번호",
      revision_kind: "제개정구분",
      effective_on: "시행일자",
      status_code: "현행연혁"
    }.freeze

    # 시행일 변경은 별도 change_type 을 갖는다 (§9)
    EFFECTIVE_FIELD = :effective_on

    Result = Struct.new(:level, :change_type, :summary, :machine_diff, keyword_init: true)

    class << self
      # old_version 이 nil 이면 최초 수집(기준선)이다.
      def compare(old_version, new_metadata, new_hash, new_content: nil)
        return baseline(new_metadata, new_hash) if old_version.nil?

        old_meta = symbolize(old_version.raw_metadata)
        new_meta = symbolize(new_metadata)
        meta_changes = metadata_changes(old_meta, new_meta)
        hash_changed = old_version.content_hash != new_hash

        return no_change if !hash_changed && meta_changes.empty?

        level, change_type = classify(meta_changes, hash_changed)
        section_diff = new_content ? section_changes(old_version.normalized_content, new_content) : {}
        level = 3 if section_diff.present? && level < 3

        Result.new(
          level: level,
          change_type: change_type,
          summary: summarize(meta_changes, hash_changed, section_diff),
          machine_diff: {
            "metadata" => meta_changes,
            "content_hash" => { "old" => old_version.content_hash, "new" => new_hash },
            "sections" => section_diff
          }.compact_blank
        )
      end

      def no_change = nil

      private

      def baseline(meta, hash)
        Result.new(
          level: 1, change_type: "NEW_DOCUMENT",
          summary: "최초 수집 — 이후 변경 감지의 기준선입니다 (이 자체는 개정이 아닙니다).",
          machine_diff: { "content_hash" => { "old" => nil, "new" => hash },
                          "metadata" => symbolize(meta).transform_values { |v| { "old" => nil, "new" => v } } }
        )
      end

      def symbolize(h) = (h || {}).to_h { |k, v| [ k.to_sym, v ] }

      def metadata_changes(old_meta, new_meta)
        META_FIELDS.keys.each_with_object({}) do |field, acc|
          o = old_meta[field].presence
          n = new_meta[field].presence
          acc[field.to_s] = { "old" => o, "new" => n } if o != n
        end
      end

      def classify(meta_changes, hash_changed)
        return [ 2, "REPEALED" ] if meta_changes.dig("status_code", "new").to_s.include?("연혁")
        return [ 2, "EFFECTIVE_DATE_CHANGED" ] if meta_changes.key?(EFFECTIVE_FIELD.to_s)
        return [ 2, "METADATA_CHANGED" ] if meta_changes.any?

        [ 1, "CONTENT_CHANGED" ] if hash_changed
      end

      # Level 3 — 조문 단위. "제N조" 헤더로 쪼개 비교한다.
      ARTICLE_RE = /^\s*(제\s?\d+조(?:의\s?\d+)?)/

      def section_changes(old_content, new_content)
        return {} if old_content.blank? || new_content.blank?

        o = split_articles(old_content)
        n = split_articles(new_content)
        added   = n.keys - o.keys
        removed = o.keys - n.keys
        modified = (o.keys & n.keys).select { |k| o[k] != n[k] }
        return {} if added.empty? && removed.empty? && modified.empty?

        { "added" => added, "removed" => removed, "modified" => modified }.compact_blank
      end

      def split_articles(content)
        content.to_s.split(/(?=#{ARTICLE_RE.source})/).each_with_object({}) do |chunk, acc|
          key = chunk[ARTICLE_RE, 1]
          next if key.blank?

          acc[key.gsub(/\s+/, "")] = chunk.strip
        end
      end

      def summarize(meta_changes, hash_changed, section_diff)
        parts = meta_changes.map do |field, v|
          "#{META_FIELDS[field.to_sym] || field}: #{v['old'] || '(없음)'} → #{v['new'] || '(없음)'}"
        end
        if section_diff.present?
          parts << "조문 변경 — 신설 #{Array(section_diff['added']).size} · " \
                   "삭제 #{Array(section_diff['removed']).size} · 수정 #{Array(section_diff['modified']).size}"
        end
        parts << "본문 해시 변경" if hash_changed && parts.empty?
        parts.join(" / ")
      end
    end
  end
end
