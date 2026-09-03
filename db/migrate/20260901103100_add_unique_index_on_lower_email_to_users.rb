# frozen_string_literal: true

class AddUniqueIndexOnLowerEmailToUsers < ActiveRecord::Migration[7.2]
  def up
    remove_index :users, :email
    execute "CREATE UNIQUE INDEX index_users_on_lower_email ON users (lower(email))"
  end

  def down
    remove_index :users, name: "index_users_on_lower_email"
    add_index :users, :email
  end
end
