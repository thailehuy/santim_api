class Bid < ActiveRecord::Base
  attr_accessible :amount, :note, :user

  belongs_to :user
  belongs_to :biddable, polymorphic: true
end
