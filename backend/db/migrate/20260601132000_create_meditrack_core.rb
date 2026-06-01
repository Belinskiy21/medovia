class CreateMeditrackCore < ActiveRecord::Migration[8.1]
  def change
    create_table :healthcare_units do |t|
      t.string :name, null: false
      t.string :location, null: false

      t.timestamps
    end

    create_table :medications do |t|
      t.references :healthcare_unit, null: false, foreign_key: true
      t.string :name, null: false
      t.string :atc_code, null: false
      t.string :form, null: false
      t.string :strength, null: false
      t.integer :inventory_balance, null: false, default: 0
      t.integer :minimum_threshold, null: false, default: 10
      t.string :category

      t.timestamps
    end

    add_index :medications, [ :healthcare_unit_id, :atc_code, :name ], name: "index_medications_on_unit_atc_name"

    create_table :orders do |t|
      t.references :healthcare_unit, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.string :created_by, null: false
      t.datetime :sent_at
      t.datetime :confirmed_at
      t.datetime :delivered_at

      t.timestamps
    end

    create_table :order_lines do |t|
      t.references :order, null: false, foreign_key: true
      t.references :medication, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end

    create_table :audit_logs do |t|
      t.string :actor, null: false
      t.string :role, null: false
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, [ :auditable_type, :auditable_id ]
    add_index :audit_logs, :created_at
  end
end
