# frozen_string_literal: true

# P1.5 §11·§12·§32 — 콘텐츠 freshness 상태 전이.
#
# ⚠️ 이 서비스가 건드리는 컬럼은 `freshness_state` · `freshness_state_at` · `last_change_event_id`
#    **오직 세 개**다. 본문·제목·법령 텍스트는 절대 수정하지 않는다(§4·§48).
class ContentFreshnessUpdater
  # 엔진이 쓸 수 있는 컬럼 화이트리스트 — 회귀 테스트가 이 상수를 검사한다.
  WRITABLE_COLUMNS = %w[freshness_state freshness_state_at last_change_event_id].freeze

  STATES = %w[
    CURRENT REVIEW_DUE CHANGE_DETECTED REVIEW_REQUIRED
    VERIFIED_AFTER_CHANGE STALE_SUSPECTED SOURCE_UNAVAILABLE UNKNOWN
  ].freeze

  class << self
    # 변경 감지 후: 영향 태스크가 생겼으면 REVIEW_REQUIRED, 아니면 CHANGE_DETECTED
    def apply_change_event(change_event, tasks)
      tasks.each do |task|
        record = resolve_record(task.affected_type, task.affected_id)
        next if record.nil?

        # 자동 판정에서 영향 없음이면 §47 에 따라 CURRENT 로 되돌린다.
        # 그 외에는 사람이 볼 때까지 REVIEW_REQUIRED 로 둔다.
        state = task.impact_class == "NO_IMPACT" ? "CURRENT" : "REVIEW_REQUIRED"
        write(record, state, change_event.id)
      end
    end

    # 검토 결정 후 상태 전이 (§47 state machine)
    def apply_decision(task)
      record = resolve_record(task.affected_type, task.affected_id)
      return nil if record.nil?

      # ⚠️ IMPACT_CONFIRMED 를 VERIFIED_AFTER_CHANGE 로 보내면 안 된다.
      #    영향이 있다고 사람이 확인한 콘텐츠에 "검증됨" 배지가 붙는다 — P0 TR-02 와 같은 종류의 사고다.
      #    깨끗한 상태에 도달하는 유일한 경로는 "영향 없음" 판정뿐이다.
      state =
        case task.status
        when "NO_IMPACT"          then "VERIFIED_AFTER_CHANGE"  # 사람이 보고 그대로 유효하다고 판정
        when "IMPACT_CONFIRMED"   then "REVIEW_REQUIRED"        # 영향 있음 — 아직 반영 전
        when "UPDATE_REQUIRED"    then "REVIEW_REQUIRED"
        when "NEEDS_LEGAL_REVIEW" then "REVIEW_REQUIRED"
        when "DEFERRED"           then "REVIEW_REQUIRED"
        else "UNKNOWN"
        end

      write(record, state, task.authority_change_event_id)
    end

    # 출처 장애가 길어지면 콘텐츠를 지우지 않고 상태만 낮춘다(§32)
    def mark_source_unavailable(document)
      ContentAuthorityLink.where(authority_document_id: document.id).find_each do |link|
        record = resolve_record(link.content_type, link.content_id)
        next if record.nil?

        write(record, "SOURCE_UNAVAILABLE", nil)
      end
    end

    private

    def resolve_record(type, id)
      return nil unless ContentAuthorityLink::AR_CONTENT_TYPES.include?(type.to_s)
      return nil if id.blank?

      type.constantize.find_by(id: id)
    end

    # 화이트리스트 컬럼만, 콜백 없이 쓴다.
    # update_columns 를 쓰는 이유: 본문 변경 신호(IndexNow ping·캐시 무효화)를 발생시키면 안 된다.
    def write(record, state, change_event_id)
      raise ArgumentError, "알 수 없는 freshness 상태: #{state}" unless STATES.include?(state)

      attrs = { "freshness_state" => state, "freshness_state_at" => Time.current,
                "last_change_event_id" => change_event_id }
      unknown = attrs.keys - WRITABLE_COLUMNS
      raise ArgumentError, "허용되지 않은 컬럼 쓰기 시도: #{unknown.join(', ')}" if unknown.any?

      record.update_columns(attrs)
      record
    end
  end
end
