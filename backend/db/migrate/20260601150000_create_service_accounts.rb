class CreateServiceAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :service_accounts do |t|
      t.string :name, null: false
      t.string :identifier, null: false
      t.string :role, null: false
      t.string :token_digest, null: false

      t.timestamps
    end

    add_index :service_accounts, :identifier, unique: true
    add_index :service_accounts, :role
  end
end
