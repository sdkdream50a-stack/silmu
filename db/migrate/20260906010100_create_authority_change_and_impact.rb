# frozen_string_literal: true

# P1.5 — 변경 이벤트 · 영향 그래프 · 검토 큐 · 검증 이벤트
#
# 핵심 규칙(§12): "법령 변경 감지" ≠ "콘텐츠가 틀림".
#   변경이 감지되면 CHANGE_DETECTED / REVIEW_REQUIRED 로 가고,
#   실제 영향 여부는 **사람이 판정**한다.
class CreateAuthorityChangeAndImpact < ActiveRecord::Migration[8.1]
  # FK 검증(validate_foreign_key)은 쓰기를 막은 트랜잭션 안에서 실행하면 위험하다.
  disable_ddl_transaction!

  def change
    # ── 변경 이벤트 (§8) ───────────────────────────────────
    create_table :authority_change_events do |t|
      t.references :authority_document, null: false, foreign_key: true
      t.bigint   :old_version_id
      t.bigint   :new_version_id,       null: false
      t.datetime :detected_at,          null: false
      t.string   :change_type,          null: false  # NEW_DOCUMENT | CONTENT_CHANGED | METADATA_CHANGED |
      # EFFECTIVE_DATE_CHANGED | REPEALED
      t.integer  :diff_level                          # 1 hash / 2 metadata / 3 article / 4 paragraph (§20)
      t.text     :diff_summary
      t.jsonb    :machine_diff,         null: false, default: {}
      t.date     :effective_at                        # 이 변경이 시행되는 날
      t.string   :impact_status,        null: false, default: "PENDING"
      # PENDING | ANALYZED | NO_CONTENT_LINKED
      t.string   :review_status,        null: false, default: "OPEN"
      # OPEN | IN_REVIEW | RESOLVED
      t.timestamps
    end
    add_index :authority_change_events, [ :authority_document_id, :detected_at ]
    add_index :authority_change_events, :review_status
    add_index :authority_change_events, :effective_at
    # 같은 테이블을 두 컬럼이 참조하므로 create_table 안에서 선언할 수 없다.
    add_foreign_key :authority_change_events, :authority_versions, column: :old_version_id, validate: false
    validate_foreign_key :authority_change_events, :authority_versions, column: :old_version_id
    add_foreign_key :authority_change_events, :authority_versions, column: :new_version_id, validate: false
    validate_foreign_key :authority_change_events, :authority_versions, column: :new_version_id

    # ── 콘텐츠 ↔ 근거 연결 (§8·§13) ────────────────────────
    # Tool / Template 은 ActiveRecord 모델이 아니므로 content_key 로 참조한다.
    create_table :content_authority_links do |t|
      t.string  :content_type,   null: false   # Topic | Guide | AuditCase | Tool | Template
      t.bigint  :content_id                    # AR 레코드일 때
      t.string  :content_key                   # Tool/Template 처럼 코드 기반일 때 (예: "contract-method")
      t.references :authority_document, null: false, foreign_key: true
      t.string  :article_reference             # "제25조"
      t.string  :clause_reference              # "제1항 제5호"
      t.string  :relationship_type, null: false, default: "GOVERNED_BY"
      # GOVERNED_BY | INTERPRETS | EVIDENCED_BY | CALCULATES_WITH
      t.string  :confidence,        null: false, default: "MEDIUM"  # HIGH | MEDIUM | LOW
      t.string  :derivation_source                                   # 어떻게 만들어졌나 (감사 추적)
      t.datetime :verified_at
      t.timestamps
    end
    add_index :content_authority_links, [ :content_type, :content_id ]
    add_index :content_authority_links, [ :content_type, :content_key ]
    # authority_document_id 인덱스는 t.references 가 이미 생성한다 (중복 추가 금지)
    add_index :content_authority_links,
              [ :content_type, :content_id, :content_key, :authority_document_id, :article_reference ],
              unique: true, name: "index_content_authority_links_uniqueness"

    # ── 검토 큐 (§27·§28) ──────────────────────────────────
    create_table :authority_review_tasks do |t|
      t.references :authority_change_event, null: false, foreign_key: true
      t.string   :affected_type,  null: false
      t.bigint   :affected_id
      t.string   :affected_key
      t.string   :affected_label                      # 화면 표시용 (제목·slug)
      t.string   :impact_class,   null: false, default: "UNKNOWN"
      # DIRECT | INDIRECT | POSSIBLE | NO_IMPACT | UNKNOWN (§14)
      t.text     :impact_reason
      t.integer  :priority,       null: false, default: 3   # 1 높음 ~ 5 낮음
      t.string   :status,         null: false, default: "OPEN"
      # OPEN | IN_REVIEW | IMPACT_CONFIRMED | NO_IMPACT |
      # UPDATE_REQUIRED | NEEDS_LEGAL_REVIEW | DEFERRED
      t.string   :assigned_to
      t.datetime :reviewed_at
      t.text     :review_note
      t.timestamps
    end
    add_index :authority_review_tasks, [ :status, :priority ]
    add_index :authority_review_tasks, [ :affected_type, :affected_id ]
    add_index :authority_review_tasks, [ :authority_change_event_id, :affected_type, :affected_id, :affected_key ],
              unique: true, name: "index_authority_review_tasks_uniqueness"

    # ── 검증 이벤트 (§29) ──────────────────────────────────
    # 콘텐츠의 updated_at 만으로 현행화 이력을 표현하지 않는다.
    create_table :authority_verification_events do |t|
      t.string   :content_type,  null: false
      t.bigint   :content_id
      t.string   :content_key
      t.bigint   :authority_version_id
      t.bigint   :authority_review_task_id
      t.string   :reviewer,      null: false
      t.datetime :reviewed_at,   null: false
      t.string   :result,        null: false   # IMPACT_CONFIRMED | NO_IMPACT | UPDATE_REQUIRED |
      # NEEDS_LEGAL_REVIEW | DEFERRED
      t.text     :note
      t.timestamps
    end
    add_index :authority_verification_events, [ :content_type, :content_id ]
    add_index :authority_verification_events, :reviewed_at
    add_foreign_key :authority_verification_events, :authority_versions,
                    column: :authority_version_id, validate: false
    validate_foreign_key :authority_verification_events, :authority_versions, column: :authority_version_id
    add_foreign_key :authority_verification_events, :authority_review_tasks,
                    column: :authority_review_task_id, validate: false
    validate_foreign_key :authority_verification_events, :authority_review_tasks,
                         column: :authority_review_task_id
  end
end
