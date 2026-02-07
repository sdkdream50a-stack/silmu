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

ActiveRecord::Schema[8.1].define(version: 2026_02_07_154821) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "audit_cases", force: :cascade do |t|
    t.text "action_taken"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "detail"
    t.text "issue"
    t.string "legal_basis"
    t.text "lesson"
    t.boolean "published", default: true
    t.string "severity"
    t.string "slug"
    t.string "title"
    t.string "topic_slug"
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0
    t.index ["slug"], name: "index_audit_cases_on_slug", unique: true
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

  create_table "topics", force: :cascade do |t|
    t.text "audit_cases"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "decree_content"
    t.text "faqs"
    t.string "flowchart_url"
    t.string "infographic_url"
    t.text "interpretation_content"
    t.text "keywords"
    t.text "law_content"
    t.string "name", null: false
    t.integer "parent_id"
    t.text "practical_tips"
    t.boolean "published", default: false
    t.text "qa_content"
    t.text "regulation_content"
    t.text "rule_content"
    t.string "slug", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.integer "view_count", default: 0
    t.index ["category"], name: "index_topics_on_category"
    t.index ["parent_id"], name: "index_topics_on_parent_id"
    t.index ["published"], name: "index_topics_on_published"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
