class EnforceSingleMembershipPerUnit < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      DELETE FROM memberships keep
      USING memberships remove
      WHERE keep.user_id = remove.user_id
        AND keep.healthcare_unit_id = remove.healthcare_unit_id
        AND keep.id < remove.id
    SQL

    remove_index :memberships, [ :user_id, :healthcare_unit_id, :role ]
    add_index :memberships, [ :user_id, :healthcare_unit_id ], unique: true
  end

  def down
    remove_index :memberships, [ :user_id, :healthcare_unit_id ]
    add_index :memberships, [ :user_id, :healthcare_unit_id, :role ], unique: true
  end
end
