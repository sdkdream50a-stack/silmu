# frozen_string_literal: true

# P1.5 Law & Regulation Freshness Engine — 핵심 데이터 모델
#
# 원칙: DETECT → VERSION → DIFF → IMPACT → REVIEW → VERIFY → PUBLISH
#       엔진은 READ-ONLY DETECTOR 다. 게시 콘텐츠를 절대 수정하지 않는다.
#
# 기존 `laws` 테이블을 재사용하지 않은 이유(§42 중복 방지 판단):
#   · 로컬/운영 모두 0행이며 어떤 코드도 쓰지 않는다
#   · source·content_hash·immutability·버전 이력 개념이 없다
#   · 문서 identity(AuthorityDocument)와 시점 snapshot(AuthorityVersion)을 한 테이블에 섞게 된다
#   → `laws` 는 손대지 않고 남겨 둔다(삭제하지 않음).
class CreateAuthorityFreshnessCore < ActiveRecord::Migration[8.1]
  # FK 검증(validate_foreign_key)은 쓰기를 막은 트랜잭션 안에서 실행하면 위험하다.
  disable_ddl_transaction!

  def change
    # ── 감시 대상 출처 등록부 (§16) ─────────────────────────
    create_table :authority_sources do |t|
      t.string  :key,             null: false          # 안정 식별자 (예: "moleg_law")
      t.string  :name,            null: false
      t.string  :agency
      t.string  :source_type,     null: false          # STRUCTURED_API | STRUCTURED_HTML | UNSTRUCTURED_PDF ...
      t.integer :authority_tier,  null: false, default: 1  # 1~4 (§7)
      t.string  :jurisdiction                          # NATIONAL | LOCAL | EDUCATION | INSTITUTION
      t.string  :region                                # ALL 또는 시도명
      t.string  :official_url
      t.string  :fetch_strategy,  null: false          # law_api | http_html | http_pdf | manual
      t.boolean :enabled,         null: false, default: true
      t.integer :check_interval_hours, null: false, default: 168  # 기본 주간
      t.datetime :last_checked_at
      t.datetime :last_success_at
      t.integer :failure_count,   null: false, default: 0
      t.string  :last_failure_kind                     # FETCH_FAILED | PARSE_FAILED | SOURCE_UNAVAILABLE
      t.text    :last_failure_message
      t.jsonb   :config,          null: false, default: {}
      t.timestamps
    end
    add_index :authority_sources, :key, unique: true
    add_index :authority_sources, [ :enabled, :last_checked_at ]

    # ── 법령/규정 identity (§8) ────────────────────────────
    create_table :authority_documents do |t|
      t.references :authority_source, null: false, foreign_key: true
      t.string  :key,                 null: false      # 안정 식별자
      t.string  :document_type,       null: false      # LAW | PRESIDENTIAL_DECREE | ADMINISTRATIVE_RULE ... (§6)
      t.string  :official_identifier                   # 법령ID·문서번호
      t.string  :title,               null: false
      t.string  :short_title
      t.string  :agency
      t.string  :jurisdiction
      t.string  :region
      t.bigint  :current_version_id                    # FK 는 versions 생성 후 추가
      t.string  :status,              null: false, default: "ACTIVE"  # ACTIVE | REPEALED | UNKNOWN
      t.boolean :has_transitional_provision            # §10 — nullable: 미판정과 false 구분
      t.boolean :transition_review_required
      t.datetime :last_checked_at
      t.timestamps
    end
    add_index :authority_documents, :key, unique: true
    add_index :authority_documents, :document_type
    add_index :authority_documents, [ :jurisdiction, :region ]

    # ── 시점 snapshot — IMMUTABLE (§8·§19) ─────────────────
    create_table :authority_versions do |t|
      t.references :authority_document, null: false, foreign_key: true
      t.string   :version_identifier                   # 법령일련번호(MST) 등
      t.string   :revision_number                      # 공포번호
      t.string   :revision_kind                        # 제개정구분명
      t.date     :promulgated_at                       # 공포일
      t.date     :published_at
      t.date     :effective_at                         # 시행일 — §9 의 핵심
      t.date     :expires_at
      t.datetime :fetched_at,           null: false
      t.string   :source_url
      t.string   :content_hash,         null: false    # normalized_content 의 SHA256
      t.jsonb    :raw_metadata,         null: false, default: {}
      t.text     :normalized_content
      t.timestamps
    end
    add_index :authority_versions, [ :authority_document_id, :content_hash ]
    add_index :authority_versions, [ :authority_document_id, :fetched_at ]
    add_index :authority_versions, :effective_at

    add_index :authority_documents, :current_version_id

    # 순환 참조(document ↔ version)라 사후 추가가 불가피하다.
    # strong_migrations 권장 패턴: 잠금 없이 추가한 뒤 별도로 검증한다.
    add_foreign_key :authority_documents, :authority_versions,
                    column: :current_version_id, validate: false
    validate_foreign_key :authority_documents, :authority_versions
  end
end
