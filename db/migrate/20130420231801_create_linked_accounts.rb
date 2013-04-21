class CreateLinkedAccounts < ActiveRecord::Migration
  def change
    create_table :linked_accounts do |t|
      t.string :type
      t.integer :user_id
      t.string :uid
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :login
      t.string :avatar_url
      t.text :oauth_token
      t.string :oauth_secret

      t.timestamps
    end
  end
end
