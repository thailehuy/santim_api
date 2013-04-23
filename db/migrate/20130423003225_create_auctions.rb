class CreateAuctions < ActiveRecord::Migration
  def change
    create_table :auctions do |t|
      t.string :title
      t.text :description
      t.integer :user_id
      t.integer :starting_bid
      t.integer :auto_win
      t.integer :bid_step
      t.integer :winning_bid_id
      t.datetime :deadline
      t.string :status
      t.integer :featured

      t.timestamps
    end
  end
end
