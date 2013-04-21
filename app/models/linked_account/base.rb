class LinkedAccount::Base < ActiveRecord::Base
  self.table_name = 'linked_accounts'

  attr_accessible :type, :user, :uid, :first_name, :last_name, :email, :login,
                  :avatar_url, :oauth_token, :oauth_secret

  belongs_to :user

  class AlreadyLinked < StandardError; end
  class OauthError < StandardError; end

  # Note: Override in subclass
  # begin OAUTH, get the code
  def self.oauth_url(options={})
    raise "Need to implement #{self.name}::oauth_url"
  end

  # Note: Override in subclass
  # exchange the code for an access_token
  def self.find_or_create_via_oauth_code(code)
    raise "Need to implement #{self.name}::find_or_create_via_oauth_code"
  end

  def self.find_by_access_token(access_token)
    linked_account_id, time, hash = (access_token||'').split('.')
    return nil if linked_account_id.blank? || time.blank? || hash.blank?
    return nil unless time.to_i > Time.now.to_i
    return nil unless (linked_account = find_by_id(linked_account_id))
    return nil unless hash == hash_access_token(linked_account, time)
    linked_account
  end

  def create_access_token
    time = 1.day.from_now.to_i
    "#{self.id}.#{time}.#{self.class.hash_access_token(self, time)}"
  end

  def link_with_user(new_user)
    raise AlreadyLinked, "Account already linked" unless self.user.nil? && new_user
    update_attributes user: new_user
  end

protected

  def self.with_https(url, &block)
    uri               = URI.parse(url)
    http              = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.verify_mode  = OpenSSL::SSL::VERIFY_NONE

    yield uri, http
  end

  def self.hash_access_token(linked_account, time)
    Digest::SHA1.hexdigest("#{linked_account.id}.#{time}.delicious-lorem-ipsum-c78fd76fds45cx45c64fds66f78a9sd7")
  end
end
