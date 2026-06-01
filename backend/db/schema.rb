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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_153000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor", null: false
    t.bigint "auditable_id"
    t.string "auditable_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
  end

  create_table "healthcare_units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text), lower((location)::text)", name: "index_healthcare_units_on_lower_name_location", unique: true
  end

  create_table "medications", force: :cascade do |t|
    t.string "atc_code", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.string "form", null: false
    t.bigint "healthcare_unit_id", null: false
    t.integer "inventory_balance", default: 0, null: false
    t.integer "minimum_threshold", default: 10, null: false
    t.string "name", null: false
    t.string "strength", null: false
    t.datetime "updated_at", null: false
    t.index "healthcare_unit_id, lower((atc_code)::text), lower((form)::text), lower((strength)::text)", name: "index_medications_on_unit_atc_form_strength", unique: true
    t.index ["healthcare_unit_id", "atc_code", "name"], name: "index_medications_on_unit_atc_name"
    t.index ["healthcare_unit_id"], name: "index_medications_on_healthcare_unit_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "healthcare_unit_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["healthcare_unit_id"], name: "index_memberships_on_healthcare_unit_id"
    t.index ["user_id", "healthcare_unit_id"], name: "index_memberships_on_user_id_and_healthcare_unit_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "medication_id", null: false
    t.bigint "order_id", null: false
    t.integer "quantity", null: false
    t.datetime "updated_at", null: false
    t.index ["medication_id"], name: "index_order_lines_on_medication_id"
    t.index ["order_id", "medication_id"], name: "index_order_lines_on_order_medication", unique: true
    t.index ["order_id"], name: "index_order_lines_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "created_by", null: false
    t.datetime "delivered_at"
    t.bigint "healthcare_unit_id", null: false
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["healthcare_unit_id"], name: "index_orders_on_healthcare_unit_id"
  end

  create_table "service_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "identifier", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_service_accounts_on_identifier", unique: true
    t.index ["role"], name: "index_service_accounts_on_role"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "medications", "healthcare_units"
  add_foreign_key "memberships", "healthcare_units"
  add_foreign_key "memberships", "users"
  add_foreign_key "order_lines", "medications"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "orders", "healthcare_units"
end
