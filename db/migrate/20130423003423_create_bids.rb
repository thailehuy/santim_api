class CreateBids < ActiveRecord::Migration
  def change
    create_table :bids do |t|
      t.integer :amount
      t.integer :biddable_id
      t.string :biddable_type
      t.integer :user_id
      t.text :note

      t.timestamps
    end
  end
end
