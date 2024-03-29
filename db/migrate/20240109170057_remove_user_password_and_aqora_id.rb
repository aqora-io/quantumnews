# frozen_string_literal: true

class RemoveUserPasswordAndAqoraId < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :aqora_id, :string
    add_index :users, :aqora_id, unique: true
    add_column :users, :aqora_oauth_token, :string

    remove_column :users, :password_digest
    remove_column :users, :password_reset_token
  end

  def down
    remove_column :users, :aqora_id
    remove_column :users, :aqora_oauth_token
  end
end
