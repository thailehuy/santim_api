class CreateHunts < ActiveRecord::Migration
  def change
    create_table :hunts do |t|
      t.string :title
      t.text :description
      t.integer :user_id
      t.text :reward
      t.integer :winning_bid_id
      t.datetime :deadline
      t.string :status
      t.integer :featured

      t.timestamps
    end
  end
end
