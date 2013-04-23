class Auction < ActiveRecord::Base
  attr_accessible :auto_win, :bid_step, :deadline, :description, :featured, :starting_bid, :status, :title, :user, :winning_bid

  belongs_to :user
  has_many :bids, as: :biddable

  belongs_to :winning_bid, class_name: "Bid", foreign_key: :winning_bid_id
end
