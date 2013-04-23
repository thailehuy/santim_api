class Hunt < ActiveRecord::Base
  attr_accessible :deadline, :description, :featured, :reward, :status, :title, :user, :winning_bid_id

  belongs_to :user
  has_many :bids, as: :biddable

  belongs_to :winning_bid, class_name: "Bid", foreign_key: :winning_bid_id
end
