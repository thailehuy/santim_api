class User < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation, :last_seen_at, :display_name
  attr_accessor :password, :password_confirmation

  has_many :auctions
  has_many :hunts
  has_many :bids
  has_many :auction_bids, through: :auctions, source: :bids, class_name: "Bid"
  has_many :hunt_bids, through: :hunts, source: :bids, class_name: "Bid"

  # if a new password was set, validate it.  if there isn't an encrypted password, require one
  validates :password,
            length: { minimum: 8 },
            if: 'hashed_password.blank? || !password.blank?'

  before_create :hash_password

  class << self
    def authenticate(email, password)
      find_by_email(email).try(:authenticate, password)
    end

    def find_by_access_token(access_token = '')
      seed, user_id, hash = access_token.split('.')
      return nil if user_id.blank? || seed.blank? || hash.blank?
      return nil if Time.now.to_i.to_s > seed
      return nil unless (user = find_by_id(user_id))
      return nil unless hash == hash_access_token(user, seed)
      user
    end
  end

  def authenticate(password)
    return self if generate_hash_password(password) == self.hashed_password
    return nil
  end

  # only update if it's been over an hour... this saves updating the DB for *every* request
  def was_seen!
    update_attribute(:last_seen_at, Time.now) if valid? && (last_seen_at.nil? || last_seen_at < 1.hour.ago)
  end

  def create_access_token
    "#{hash_seed}.#{self.id}.#{User.hash_access_token(self, hash_seed)}"
  end

  def hash_seed
    time = 1.day.from_now.to_i
    # Digest::SHA1.hexdigest(time)
  end

  protected

  def self.hash_access_token(user, seed)
    Digest::SHA1.hexdigest("#{user.id}.#{seed}.super-awesome-impeccable-seed-e381d4ce0a9e1116e0c3632bcc1f7588ca9512308ac09037fcd3a4cd")
  end

  def hash_password
    self.hashed_password = generate_hash_password(self.password)
  end

  def generate_hash_password(password)
    Digest::SHA1.hexdigest("#{password}-with-a-very-secret-key")
  end
end
