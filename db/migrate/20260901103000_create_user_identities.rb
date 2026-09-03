# frozen_string_literal: true

class CreateUserIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_identities do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.boolean :email_verified, null: false, default: false
      t.boolean :primary, null: false, default: false

      t.timestamps
    end

    add_index :user_identities, %i[provider uid], unique: true

    add_index(
      :user_identities, 
      :user_id, 
      unique: true, 
      where: "primary",
      name: "index_user_identities_on_user_id_primary"
    )

    remove_column :users, :uid, :string, null: false
  end
end
