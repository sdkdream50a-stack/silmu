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

ActiveRecord::Schema[8.1].define(version: 2026_04_22_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "audit_cases", force: :cascade do |t|
    t.text "action_taken"
    t.string "category"
    t.jsonb "checkpoints", default: []
    t.datetime "created_at", null: false
    t.text "detail"
    t.string "infographic_url"
    t.text "issue"
    t.string "legal_basis"
    t.text "lesson"
    t.boolean "published", default: true
    t.boolean "repeated_issue", default: false
    t.integer "sector", default: 0, null: false
    t.string "severity"
    t.string "slug"
    t.string "title"
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0
    t.index ["published", "category"], name: "index_audit_cases_on_published_and_category"
    t.index ["published", "created_at"], name: "index_audit_cases_on_published_and_created_at"
    t.index ["published", "sector"], name: "index_audit_cases_on_published_and_sector"
    t.index ["published", "updated_at"], name: "index_audit_cases_on_published_and_updated_at"
    t.index ["slug"], name: "index_audit_cases_on_slug", unique: true
    t.index ["topic_slug"], name: "index_audit_cases_on_topic_slug"
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
    t.string "author", default: "실무팀"
    t.string "badge"
    t.string "category"
    t.string "category_color", default: "emerald"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_link"
    t.boolean "published", default: true, null: false
    t.date "published_on"
    t.jsonb "rich_media", default: {}
    t.jsonb "sections"
    t.integer "sector", default: 0, null: false
    t.string "series"
    t.integer "series_order"
    t.string "slug", null: false
    t.integer "sort_order", default: 0, null: false
    t.text "summary"
    t.string "tag"
    t.string "title", null: false
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.index ["category"], name: "index_guides_on_category"
    t.index ["published", "sector"], name: "index_guides_on_published_and_sector"
    t.index ["published", "sort_order"], name: "index_guides_on_published_and_sort_order"
    t.index ["published", "view_count"], name: "index_guides_on_published_and_view_count"
    t.index ["published"], name: "index_guides_on_published"
    t.index ["rich_media"], name: "index_guides_on_rich_media", using: :gin
    t.index ["series", "series_order"], name: "index_guides_on_series_and_series_order", where: "(series IS NOT NULL)"
    t.index ["slug"], name: "index_guides_on_slug", unique: true
    t.index ["sort_order"], name: "index_guides_on_sort_order"
    t.index ["topic_slug"], name: "index_guides_on_topic_slug"
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

  create_table "slug_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "new_slug", null: false
    t.string "old_slug", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.index ["old_slug", "resource_type"], name: "index_slug_redirects_on_old_slug_and_resource_type", unique: true
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

  create_table "topics", force: :cascade do |t|
    t.text "audit_cases"
    t.string "category"
    t.text "commentary"
    t.datetime "created_at", null: false
    t.text "decree_content"
    t.jsonb "faqs", default: []
    t.text "flowchart_mermaid"
    t.string "flowchart_url"
    t.string "infographic_url"
    t.text "interpretation_content"
    t.text "keywords"
    t.string "law_base_date"
    t.text "law_content"
    t.datetime "law_verified_at"
    t.string "name", null: false
    t.integer "parent_id"
    t.text "practical_tips"
    t.boolean "published", default: false
    t.text "qa_content"
    t.text "regulation_content"
    t.text "rule_content"
    t.integer "sector", default: 0, null: false
    t.string "slug", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.integer "view_count", default: 0
    t.index ["category"], name: "index_topics_on_category"
    t.index ["faqs"], name: "index_topics_on_faqs_jsonb", where: "(faqs <> '[]'::jsonb)", using: :gin
    t.index ["parent_id"], name: "index_topics_on_parent_id"
    t.index ["published", "category"], name: "index_topics_on_published_and_category"
    t.index ["published", "sector", "category"], name: "index_topics_on_pub_sector_cat"
    t.index ["published", "sector"], name: "index_topics_on_published_and_sector"
    t.index ["published", "updated_at"], name: "index_topics_on_published_and_updated_at"
    t.index ["published", "view_count"], name: "index_topics_on_published_and_view_count"
    t.index ["published"], name: "index_topics_on_published"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
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

  add_foreign_key "bookmarks", "users"
  add_foreign_key "calendar_data", "users"
  add_foreign_key "exam_progresses", "users"
  add_foreign_key "exam_question_comments", "users"
  add_foreign_key "law_change_subscriptions", "users"
  add_foreign_key "topic_comments", "users"
end
