class AddSlugForeignKeyConstraints < ActiveRecord::Migration[8.1]
  # P4-2: topic_slug 기반 문자열 FK 제약 추가
  #
  # ⚠️  현재 상태:
  #   - guides.topic_slug → topics.slug (string PK 참조)
  #   - audit_cases.topic_slug → topics.slug (string PK 참조)
  #   - topics.slug에 unique index 존재 (schema.rb 확인됨)
  #
  # PostgreSQL은 non-integer PK FK를 지원하나,
  # Rails add_foreign_key의 primary_key: :slug 옵션은 staging 환경 검증 필요.
  # 이 마이그레이션은 우선 orphan 레코드 정리만 수행하고,
  # FK 제약 추가는 주석 해제 후 별도 배포로 진행할 것.

  def up
    # 1단계: orphan 레코드 확인 및 정리
    valid_slugs = Topic.select(:slug)

    orphan_guides = Guide.where.not(topic_slug: [ nil, "" ])
                         .where.not(topic_slug: valid_slugs)
    if orphan_guides.any?
      Rails.logger.warn "[P4-2] Orphan guides 발견 (topic_slug 없음): #{orphan_guides.pluck(:slug, :topic_slug)}"
      orphan_guides.update_all(topic_slug: nil)
    end

    orphan_audit_cases = AuditCase.where.not(topic_slug: [ nil, "" ])
                                  .where.not(topic_slug: valid_slugs)
    if orphan_audit_cases.any?
      Rails.logger.warn "[P4-2] Orphan audit_cases 발견 (topic_slug 없음): #{orphan_audit_cases.pluck(:slug, :topic_slug)}"
      orphan_audit_cases.update_all(topic_slug: nil)
    end

    Rails.logger.info "[P4-2] orphan 정리 완료."

    # 2단계: FK 제약 추가
    # ⚠️  staging 환경에서 먼저 테스트 후 주석 해제할 것.
    #     on_update: :cascade → topics.slug 변경 시 연관 레코드도 자동 업데이트
    #
    # add_foreign_key :guides, :topics,
    #                 column: :topic_slug,
    #                 primary_key: :slug,
    #                 on_update: :cascade,
    #                 name: "fk_guides_on_topic_slug"
    #
    # add_foreign_key :audit_cases, :topics,
    #                 column: :topic_slug,
    #                 primary_key: :slug,
    #                 on_update: :cascade,
    #                 name: "fk_audit_cases_on_topic_slug"
  end

  def down
    # FK 제약 주석 해제 후 아래 추가
    # remove_foreign_key :guides, name: "fk_guides_on_topic_slug"
    # remove_foreign_key :audit_cases, name: "fk_audit_cases_on_topic_slug"
  end
end
