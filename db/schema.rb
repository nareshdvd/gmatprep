# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170602090447) do

  create_table "categories", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "description", limit: 65535
  end

  create_table "levels", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "weight",         limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.text     "description",    limit: 65535
    t.float    "question_score", limit: 24
  end

  create_table "options", force: :cascade do |t|
    t.text     "description", limit: 65535
    t.integer  "question_id", limit: 4
    t.boolean  "correct",     limit: 1
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "options", ["question_id"], name: "index_options_on_question_id", using: :btree

  create_table "papers", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "finish_time"
    t.integer  "subscription_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "papers", ["subscription_id"], name: "index_papers_on_subscription_id", using: :btree

  create_table "papers_questions", force: :cascade do |t|
    t.integer  "paper_id",        limit: 4
    t.integer  "question_id",     limit: 4
    t.integer  "question_number", limit: 4
    t.integer  "option_id",       limit: 4
    t.datetime "start_time"
    t.datetime "finish_time"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "papers_questions", ["option_id"], name: "index_papers_questions_on_option_id", using: :btree
  add_index "papers_questions", ["paper_id"], name: "index_papers_questions_on_paper_id", using: :btree
  add_index "papers_questions", ["question_id"], name: "index_papers_questions_on_question_id", using: :btree

  create_table "passages", force: :cascade do |t|
    t.string   "title",          limit: 255
    t.text     "description",    limit: 65535
    t.integer  "question_count", limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "payments", force: :cascade do |t|
    t.string   "txn_id",          limit: 255
    t.string   "status",          limit: 255
    t.float    "amount",          limit: 24
    t.string   "currency",        limit: 255
    t.string   "gm_txn_id",       limit: 255
    t.integer  "subscription_id", limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "payments", ["subscription_id"], name: "index_payments_on_subscription_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.float    "amount",         limit: 24
    t.string   "currency",       limit: 255
    t.integer  "paper_count",    limit: 4
    t.string   "interval",       limit: 255
    t.integer  "interval_count", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "questions", force: :cascade do |t|
    t.text     "description",          limit: 65535
    t.integer  "level_id",             limit: 4
    t.integer  "category_id",          limit: 4
    t.integer  "passage_id",           limit: 4
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "marked_for_free_plan", limit: 1,     default: false
    t.text     "question_text",        limit: 65535
    t.text     "explanation",          limit: 65535
  end

  add_index "questions", ["category_id"], name: "index_questions_on_category_id", using: :btree
  add_index "questions", ["level_id"], name: "index_questions_on_level_id", using: :btree
  add_index "questions", ["passage_id"], name: "index_questions_on_passage_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "roles_users", force: :cascade do |t|
    t.integer  "role_id",    limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "roles_users", ["role_id"], name: "fk_rails_9dada905f6", using: :btree
  add_index "roles_users", ["user_id"], name: "fk_rails_e2a7142459", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "plan_id",    limit: 4
    t.integer  "user_id",    limit: 4
    t.boolean  "is_active",  limit: 1
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "subscriptions", ["plan_id"], name: "index_subscriptions_on_plan_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "options", "questions"
  add_foreign_key "papers", "subscriptions"
  add_foreign_key "papers_questions", "options"
  add_foreign_key "papers_questions", "papers"
  add_foreign_key "papers_questions", "questions"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "questions", "categories"
  add_foreign_key "questions", "levels"
  add_foreign_key "questions", "passages"
  add_foreign_key "roles_users", "roles"
  add_foreign_key "roles_users", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
end
