# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_06_065000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "analytics_snapshots", force: :cascade do |t|
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "days", null: false
    t.string "label", null: false
    t.jsonb "metrics", default: {}, null: false
    t.text "notes"
    t.string "page_path", null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "index_analytics_snapshots_on_captured_at"
    t.index ["label", "page_path"], name: "index_analytics_snapshots_on_label_and_page_path"
  end

  create_table "audit_cases", force: :cascade do |t|
    t.text "action_taken"
    t.string "agency_scope_confidence"
    t.string "category"
    t.jsonb "checkpoints", default: []
    t.datetime "created_at", null: false
    t.text "detail"
    t.date "effective_at"
    t.string "freshness_state"
    t.datetime "freshness_state_at"
    t.string "infographic_url"
    t.boolean "is_reconstructed"
    t.text "issue"
    t.string "jurisdiction"
    t.bigint "last_change_event_id"
    t.datetime "last_verified_at"
    t.string "legal_basis"
    t.text "lesson"
    t.integer "org_type"
    t.string "provenance_confidence"
    t.boolean "published", default: true
    t.boolean "repeated_issue", default: false
    t.date "review_due_at"
    t.integer "sector", default: 0, null: false
    t.string "severity"
    t.string "slug"
    t.jsonb "source", default: {}
    t.string "source_agency"
    t.integer "source_page"
    t.string "source_reference"
    t.string "source_title"
    t.string "source_type"
    t.string "source_url"
    t.integer "source_year"
    t.string "target_agency", default: [], array: true
    t.string "title"
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.string "verification_method", limit: 32
    t.text "verification_note"
    t.string "verification_source", limit: 200
    t.string "verification_status"
    t.integer "view_count", default: 0
    t.index ["freshness_state"], name: "index_audit_cases_on_freshness_state"
    t.index ["is_reconstructed"], name: "index_audit_cases_on_is_reconstructed"
    t.index ["jurisdiction"], name: "index_audit_cases_on_jurisdiction"
    t.index ["published", "category"], name: "index_audit_cases_on_published_and_category"
    t.index ["published", "created_at"], name: "index_audit_cases_on_published_and_created_at"
    t.index ["published", "sector"], name: "index_audit_cases_on_published_and_sector"
    t.index ["published", "updated_at"], name: "index_audit_cases_on_published_and_updated_at"
    t.index ["review_due_at"], name: "index_audit_cases_on_review_due_at"
    t.index ["sector", "org_type"], name: "index_audit_cases_on_sector_and_org_type"
    t.index ["slug"], name: "index_audit_cases_on_slug", unique: true
    t.index ["source"], name: "index_audit_cases_on_source", using: :gin
    t.index ["source_type"], name: "index_audit_cases_on_source_type"
    t.index ["target_agency"], name: "index_audit_cases_on_target_agency", using: :gin
    t.index ["topic_slug"], name: "index_audit_cases_on_topic_slug"
    t.index ["verification_status"], name: "index_audit_cases_on_verification_status"
  end

  create_table "authority_change_events", force: :cascade do |t|
    t.bigint "authority_document_id", null: false
    t.string "change_type", null: false
    t.datetime "created_at", null: false
    t.datetime "detected_at", null: false
    t.integer "diff_level"
    t.text "diff_summary"
    t.date "effective_at"
    t.string "impact_status", default: "PENDING", null: false
    t.jsonb "machine_diff", default: {}, null: false
    t.bigint "new_version_id", null: false
    t.bigint "old_version_id"
    t.string "review_status", default: "OPEN", null: false
    t.datetime "updated_at", null: false
    t.index ["authority_document_id", "detected_at"], name: "idx_on_authority_document_id_detected_at_b0039f4ad8"
    t.index ["authority_document_id"], name: "index_authority_change_events_on_authority_document_id"
    t.index ["effective_at"], name: "index_authority_change_events_on_effective_at"
    t.index ["review_status"], name: "index_authority_change_events_on_review_status"
  end

  create_table "authority_documents", force: :cascade do |t|
    t.string "agency"
    t.bigint "authority_source_id", null: false
    t.datetime "created_at", null: false
    t.bigint "current_version_id"
    t.string "document_type", null: false
    t.boolean "has_transitional_provision"
    t.string "jurisdiction"
    t.string "key", null: false
    t.datetime "last_checked_at"
    t.string "official_identifier"
    t.string "region"
    t.string "short_title"
    t.string "status", default: "ACTIVE", null: false
    t.string "title", null: false
    t.boolean "transition_review_required"
    t.datetime "updated_at", null: false
    t.index ["authority_source_id"], name: "index_authority_documents_on_authority_source_id"
    t.index ["current_version_id"], name: "index_authority_documents_on_current_version_id"
    t.index ["document_type"], name: "index_authority_documents_on_document_type"
    t.index ["jurisdiction", "region"], name: "index_authority_documents_on_jurisdiction_and_region"
    t.index ["key"], name: "index_authority_documents_on_key", unique: true
  end

  create_table "authority_review_tasks", force: :cascade do |t|
    t.bigint "affected_id"
    t.string "affected_key"
    t.string "affected_label"
    t.string "affected_type", null: false
    t.string "assigned_to"
    t.bigint "authority_change_event_id", null: false
    t.datetime "created_at", null: false
    t.string "impact_class", default: "UNKNOWN", null: false
    t.text "impact_reason"
    t.integer "priority", default: 3, null: false
    t.text "review_note"
    t.datetime "reviewed_at"
    t.string "status", default: "OPEN", null: false
    t.datetime "updated_at", null: false
    t.index ["affected_type", "affected_id"], name: "index_authority_review_tasks_on_affected_type_and_affected_id"
    t.index ["authority_change_event_id", "affected_type", "affected_id", "affected_key"], name: "index_authority_review_tasks_uniqueness", unique: true
    t.index ["authority_change_event_id"], name: "index_authority_review_tasks_on_authority_change_event_id"
    t.index ["status", "priority"], name: "index_authority_review_tasks_on_status_and_priority"
  end

  create_table "authority_sources", force: :cascade do |t|
    t.string "agency"
    t.datetime "alerted_at"
    t.integer "authority_tier", default: 1, null: false
    t.integer "check_interval_hours", default: 168, null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "failure_count", default: 0, null: false
    t.string "fetch_strategy", null: false
    t.datetime "first_failed_at"
    t.string "jurisdiction"
    t.string "key", null: false
    t.datetime "last_checked_at"
    t.string "last_failure_kind"
    t.text "last_failure_message"
    t.datetime "last_success_at"
    t.string "name", null: false
    t.string "official_url"
    t.string "region"
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled", "last_checked_at"], name: "index_authority_sources_on_enabled_and_last_checked_at"
    t.index ["key"], name: "index_authority_sources_on_key", unique: true
  end

  create_table "authority_verification_events", force: :cascade do |t|
    t.bigint "authority_review_task_id"
    t.bigint "authority_version_id"
    t.bigint "content_id"
    t.string "content_key"
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.string "result", null: false
    t.datetime "reviewed_at", null: false
    t.string "reviewer", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type", "content_id"], name: "idx_on_content_type_content_id_baeb6ae538"
    t.index ["reviewed_at"], name: "index_authority_verification_events_on_reviewed_at"
  end

  create_table "authority_versions", force: :cascade do |t|
    t.bigint "authority_document_id", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.date "effective_at"
    t.date "expires_at"
    t.datetime "fetched_at", null: false
    t.text "normalized_content"
    t.date "promulgated_at"
    t.date "published_at"
    t.jsonb "raw_metadata", default: {}, null: false
    t.string "revision_kind"
    t.string "revision_number"
    t.string "source_url"
    t.datetime "updated_at", null: false
    t.string "version_identifier"
    t.index ["authority_document_id", "content_hash"], name: "idx_on_authority_document_id_content_hash_4864e018d4"
    t.index ["authority_document_id", "fetched_at"], name: "idx_on_authority_document_id_fetched_at_5fde8beb71"
    t.index ["authority_document_id"], name: "index_authority_versions_on_authority_document_id"
    t.index ["effective_at"], name: "index_authority_versions_on_effective_at"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.bigint "bookmarkable_id", null: false
    t.string "bookmarkable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable"
    t.index ["user_id", "bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_user_and_bookmarkable", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "cafe_articles", force: :cascade do |t|
    t.integer "article_id"
    t.string "author"
    t.string "board"
    t.integer "comment_count"
    t.datetime "created_at", null: false
    t.integer "like_count"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "view_count"
    t.datetime "written_at"
    t.index ["article_id"], name: "index_cafe_articles_on_article_id", unique: true
    t.index ["board"], name: "index_cafe_articles_on_board"
    t.index ["title"], name: "cafe_articles_title_trgm_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["view_count"], name: "index_cafe_articles_on_view_count"
  end

  create_table "calendar_data", force: :cascade do |t|
    t.jsonb "categories", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "custom_tasks", default: [], null: false
    t.json "deleted_default_tasks"
    t.jsonb "standing_checklist", default: [], null: false
    t.jsonb "task_states", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_calendar_data_on_user_id", unique: true
  end

  create_table "content_authority_links", force: :cascade do |t|
    t.string "article_reference"
    t.bigint "authority_document_id", null: false
    t.string "clause_reference"
    t.string "confidence", default: "MEDIUM", null: false
    t.bigint "content_id"
    t.string "content_key"
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "derivation_source"
    t.string "relationship_type", default: "GOVERNED_BY", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["authority_document_id"], name: "index_content_authority_links_on_authority_document_id"
    t.index ["content_type", "content_id", "content_key", "authority_document_id", "article_reference"], name: "index_content_authority_links_uniqueness", unique: true
    t.index ["content_type", "content_id"], name: "index_content_authority_links_on_content_type_and_content_id"
    t.index ["content_type", "content_key"], name: "index_content_authority_links_on_content_type_and_content_key"
  end

  create_table "content_migrations", force: :cascade do |t|
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "filename", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["filename"], name: "index_content_migrations_on_filename", unique: true
    t.index ["status"], name: "index_content_migrations_on_status"
  end

  create_table "content_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "memo"
    t.integer "priority", default: 3
    t.string "source", null: false
    t.integer "source_id"
    t.string "status", default: "open"
    t.string "title", null: false
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_content_requests_on_created_at"
    t.index ["source", "source_id"], name: "idx_content_request_source"
    t.index ["source"], name: "index_content_requests_on_source"
    t.index ["status"], name: "index_content_requests_on_status"
    t.index ["topic_slug"], name: "index_content_requests_on_topic_slug"
  end

  create_table "exam_progresses", force: :cascade do |t|
    t.jsonb "bookmarks", default: []
    t.jsonb "chapter_quizzes", default: {}
    t.jsonb "chapters", default: {}
    t.datetime "created_at", null: false
    t.string "display_name"
    t.jsonb "quizzes", default: {}
    t.integer "streak_count", default: 0
    t.jsonb "streak_history", default: []
    t.string "streak_last_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "weekly_quiz_count", default: 0
    t.string "weekly_reset_date"
    t.integer "weekly_score", default: 0, null: false
    t.integer "weekly_total", default: 0, null: false
    t.jsonb "wrong_answers", default: []
    t.index ["user_id"], name: "index_exam_progresses_on_user_id"
    t.index ["weekly_quiz_count"], name: "idx_exam_progresses_on_weekly_quiz_count"
  end

  create_table "exam_question_comments", force: :cascade do |t|
    t.string "author_name"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.integer "likes_count", default: 0
    t.integer "question_id", null: false
    t.integer "reported_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["question_id", "hidden", "likes_count"], name: "idx_exam_comments_on_qid_hidden_likes"
    t.index ["question_id"], name: "index_exam_question_comments_on_question_id"
    t.index ["user_id"], name: "index_exam_question_comments_on_user_id"
  end

  create_table "exam_question_reports", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["question_id"], name: "idx_exam_question_reports_on_qid"
  end

  create_table "exam_questions", force: :cascade do |t|
    t.integer "chapter_num", null: false
    t.integer "correct", null: false
    t.datetime "created_at", null: false
    t.string "difficulty", default: "basic", null: false
    t.text "explanation"
    t.text "options", default: "[]", null: false
    t.boolean "published", default: true, null: false
    t.text "question", null: false
    t.integer "subject_id", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_exam_questions_on_published"
    t.index ["subject_id", "chapter_num"], name: "index_exam_questions_on_subject_id_and_chapter_num"
    t.index ["subject_id"], name: "index_exam_questions_on_subject_id"
  end

  create_table "guides", force: :cascade do |t|
    t.string "agency_scope_confidence"
    t.string "author", default: "실무팀"
    t.string "badge"
    t.string "category"
    t.string "category_color", default: "emerald"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "effective_at"
    t.string "external_link"
    t.string "freshness_state"
    t.datetime "freshness_state_at"
    t.string "jurisdiction"
    t.bigint "last_change_event_id"
    t.datetime "last_verified_at"
    t.boolean "published", default: true, null: false
    t.date "published_on"
    t.date "review_due_at"
    t.jsonb "rich_media", default: {}
    t.jsonb "sections"
    t.integer "sector", default: 0, null: false
    t.string "series"
    t.integer "series_order"
    t.string "slug", null: false
    t.integer "sort_order", default: 0, null: false
    t.text "summary"
    t.string "tag"
    t.string "target_agency", default: [], array: true
    t.string "title", null: false
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.string "verification_method", limit: 32
    t.text "verification_note"
    t.string "verification_source", limit: 200
    t.string "verification_status"
    t.integer "view_count", default: 0, null: false
    t.index ["category"], name: "index_guides_on_category"
    t.index ["freshness_state"], name: "index_guides_on_freshness_state"
    t.index ["jurisdiction"], name: "index_guides_on_jurisdiction"
    t.index ["published", "sector"], name: "index_guides_on_published_and_sector"
    t.index ["published", "sort_order"], name: "index_guides_on_published_and_sort_order"
    t.index ["published", "view_count"], name: "index_guides_on_published_and_view_count"
    t.index ["published"], name: "index_guides_on_published"
    t.index ["review_due_at"], name: "index_guides_on_review_due_at"
    t.index ["rich_media"], name: "index_guides_on_rich_media", using: :gin
    t.index ["series", "series_order"], name: "index_guides_on_series_and_series_order", where: "(series IS NOT NULL)"
    t.index ["slug"], name: "index_guides_on_slug", unique: true
    t.index ["sort_order"], name: "index_guides_on_sort_order"
    t.index ["target_agency"], name: "index_guides_on_target_agency", using: :gin
    t.index ["topic_slug"], name: "index_guides_on_topic_slug"
    t.index ["verification_status"], name: "index_guides_on_verification_status"
  end

  create_table "law_change_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "topic_name"
    t.string "topic_slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email", "topic_slug"], name: "index_law_change_subscriptions_on_email_and_topic_slug", unique: true
    t.index ["topic_slug"], name: "index_law_change_subscriptions_on_topic_slug"
    t.index ["user_id"], name: "index_law_change_subscriptions_on_user_id"
  end

  create_table "laws", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.date "effective_date"
    t.string "law_id"
    t.string "law_type"
    t.string "ministry"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["law_id"], name: "index_laws_on_law_id"
    t.index ["law_type"], name: "index_laws_on_law_type"
  end

  create_table "search_logs", force: :cascade do |t|
    t.integer "audit_case_count", default: 0, null: false
    t.datetime "clicked_at"
    t.integer "clicked_result_rank"
    t.string "clicked_result_type"
    t.datetime "created_at", null: false
    t.integer "guide_count", default: 0, null: false
    t.string "ip_hash"
    t.string "query", limit: 200, null: false
    t.string "source", limit: 20
    t.integer "template_count", default: 0, null: false
    t.integer "tool_count", default: 0, null: false
    t.integer "topic_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "zero_result", default: false, null: false
    t.index ["created_at"], name: "index_search_logs_on_created_at"
    t.index ["query"], name: "index_search_logs_on_query"
    t.index ["zero_result", "created_at"], name: "index_search_logs_on_zero_result_and_created_at"
  end

  create_table "slug_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "new_slug", null: false
    t.string "old_slug", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.index ["old_slug", "resource_type"], name: "index_slug_redirects_on_old_slug_and_resource_type", unique: true
  end

  create_table "standard_terms", force: :cascade do |t|
    t.string "agency_name"
    t.datetime "created_at", null: false
    t.string "data_type"
    t.text "description"
    t.string "domain_classification"
    t.integer "max_length"
    t.string "revision_round"
    t.jsonb "synonyms", default: [], null: false
    t.string "term_english"
    t.string "term_korean", null: false
    t.datetime "updated_at", null: false
    t.index ["synonyms"], name: "index_standard_terms_on_synonyms", using: :gin
    t.index ["term_korean"], name: "index_standard_terms_on_term_korean", unique: true
  end

  create_table "task_guides", force: :cascade do |t|
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "status", default: 0
    t.string "task_title", null: false
    t.datetime "updated_at", null: false
    t.index ["task_title"], name: "index_task_guides_on_task_title", unique: true
  end

  create_table "topic_comments", force: :cascade do |t|
    t.text "body", null: false
    t.integer "comment_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.boolean "is_official", default: false, null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "parent_id"
    t.string "topic_slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["parent_id"], name: "index_topic_comments_on_parent_id"
    t.index ["topic_slug", "hidden", "created_at"], name: "index_topic_comments_on_topic_slug_and_hidden_and_created_at"
    t.index ["topic_slug"], name: "index_topic_comments_on_topic_slug"
    t.index ["user_id"], name: "index_topic_comments_on_user_id"
  end

  create_table "topic_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.integer "event_value"
    t.string "ip_hash"
    t.string "topic_slug", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_topic_events_on_created_at"
    t.index ["topic_slug", "event_type"], name: "idx_topic_events_slug_type"
    t.index ["topic_slug"], name: "index_topic_events_on_topic_slug"
  end

  create_table "topic_feedbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_hash"
    t.text "memo"
    t.integer "rating", null: false
    t.string "topic_slug", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_topic_feedbacks_on_created_at"
    t.index ["topic_slug", "ip_hash"], name: "idx_topic_feedback_dedupe"
    t.index ["topic_slug"], name: "index_topic_feedbacks_on_topic_slug"
    t.index ["user_id"], name: "index_topic_feedbacks_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "agency_scope_confidence"
    t.text "audit_cases"
    t.string "category"
    t.text "commentary"
    t.datetime "created_at", null: false
    t.text "decree_content"
    t.date "effective_at"
    t.jsonb "faqs", default: []
    t.text "flowchart_mermaid"
    t.string "flowchart_url"
    t.string "freshness_state"
    t.datetime "freshness_state_at"
    t.jsonb "howto_steps", default: []
    t.string "infographic_url"
    t.text "interpretation_content"
    t.string "jurisdiction"
    t.text "keywords"
    t.bigint "last_change_event_id"
    t.datetime "last_verified_at"
    t.string "law_base_date"
    t.text "law_content"
    t.datetime "law_verified_at"
    t.string "name", null: false
    t.boolean "needs_review", default: false, null: false
    t.integer "org_type"
    t.integer "parent_id"
    t.text "practical_tips"
    t.boolean "published", default: false
    t.text "qa_content"
    t.jsonb "quick_stats", default: []
    t.text "regulation_content"
    t.date "review_due_at"
    t.datetime "review_flagged_at"
    t.string "review_reason"
    t.text "rule_content"
    t.integer "sector", default: 0, null: false
    t.string "slug", null: false
    t.text "summary"
    t.string "target_agency", default: [], array: true
    t.datetime "updated_at", null: false
    t.string "verification_method", limit: 32
    t.text "verification_note"
    t.string "verification_source", limit: 200
    t.string "verification_status"
    t.string "video_url"
    t.integer "view_count", default: 0
    t.index ["category"], name: "index_topics_on_category"
    t.index ["faqs"], name: "index_topics_on_faqs_jsonb", where: "(faqs <> '[]'::jsonb)", using: :gin
    t.index ["freshness_state"], name: "index_topics_on_freshness_state"
    t.index ["jurisdiction"], name: "index_topics_on_jurisdiction"
    t.index ["needs_review"], name: "index_topics_on_needs_review"
    t.index ["parent_id"], name: "index_topics_on_parent_id"
    t.index ["published", "category"], name: "index_topics_on_published_and_category"
    t.index ["published", "sector", "category"], name: "index_topics_on_pub_sector_cat"
    t.index ["published", "sector"], name: "index_topics_on_published_and_sector"
    t.index ["published", "updated_at"], name: "index_topics_on_published_and_updated_at"
    t.index ["published", "view_count"], name: "index_topics_on_published_and_view_count"
    t.index ["published"], name: "index_topics_on_published"
    t.index ["review_due_at"], name: "index_topics_on_review_due_at"
    t.index ["sector", "org_type"], name: "index_topics_on_sector_and_org_type"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
    t.index ["target_agency"], name: "index_topics_on_target_agency", using: :gin
    t.index ["verification_status"], name: "index_topics_on_verification_status"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "name"
    t.boolean "newsletter_agreed", default: false, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "authority_change_events", "authority_documents"
  add_foreign_key "authority_change_events", "authority_versions", column: "new_version_id"
  add_foreign_key "authority_change_events", "authority_versions", column: "old_version_id"
  add_foreign_key "authority_documents", "authority_sources"
  add_foreign_key "authority_documents", "authority_versions", column: "current_version_id"
  add_foreign_key "authority_review_tasks", "authority_change_events"
  add_foreign_key "authority_verification_events", "authority_review_tasks"
  add_foreign_key "authority_verification_events", "authority_versions"
  add_foreign_key "authority_versions", "authority_documents"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "calendar_data", "users"
  add_foreign_key "content_authority_links", "authority_documents"
  add_foreign_key "exam_progresses", "users"
  add_foreign_key "exam_question_comments", "users"
  add_foreign_key "law_change_subscriptions", "users"
  add_foreign_key "topic_comments", "users"
end
