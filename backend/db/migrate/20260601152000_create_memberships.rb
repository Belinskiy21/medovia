class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :healthcare_unit, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :memberships, [ :user_id, :healthcare_unit_id, :role ], unique: true

    execute <<~SQL.squish
      INSERT INTO memberships (user_id, healthcare_unit_id, role, created_at, updated_at)
      SELECT users.id, healthcare_units.id, users.role, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      CROSS JOIN healthcare_units
    SQL

    remove_index :users, :role
    remove_column :users, :role, :string, null: false
  end
end
