class LinkedAccount::Twitter < LinkedAccount::Base
  # use the Oauth gem to handle this, because Oauth 1.1 is pure ass.
  def self.oauth_url(options={})
    @oauth_request_token = oauth_consumer.get_request_token(
      oauth_callback: "#{Api::Application.config.api_url}auth/twitter/callback",
      state:          (options[:state].to_json unless options[:state].blank?)
    )
    session[:twitter_oauth_request_token] = @oauth_request_token
    @oauth_request_token.authorize_url
  end

  def self.find_or_create_via_request_token(request_token)
    access_token = request_token.get_access_token

    user_info_response = access_token.get("/1.1/users/show.json?screen_name=#{access_token.params['screen_name']}")

    user_info = JSON.parse(user_info_response.body).with_indifferent_access

    # find or create Twitter account
    first_name, last_name = user_info['name'].split(/\s+/)
    linked_account = LinkedAccount::Twitter.find_or_create_by_uid(
      uid:        user_info['id'],
      first_name: first_name,
      last_name:  last_name,
      login:      user_info['screen_name'],
      email:      nil, # Note: email addresses are not available through the Twitter API
      avatar_url: user_info['profile_image_url_https']
    )

    logger.error "\n#{access_token.params}\n"

    # update with new oauth tokens and avatar url
    linked_account.update_attributes(
      oauth_token:  access_token.params[:oauth_token],
      oauth_secret: access_token.params[:oauth_token_secret],
      avatar_url:   user_info['profile_image_url_https']
    )

    linked_account
  end

  def friend_ids
    return [] if oauth_token.blank? or oauth_secret.blank?

    build_access_token do |api|
      response = api.get('/1.1/friends/ids.json')

      if (200...300).cover? response.code.to_i
        data = JSON.parse(response.body).with_indifferent_access
        data[:ids]
      else
        update_attributes(oauth_token: nil, oauth_secret: nil) and []
      end
    end
  end

  def build_access_token(&block)
    yield OAuth::AccessToken.new(self.class.oauth_consumer, oauth_token, oauth_secret)
  end

protected

  def self.oauth_consumer
    OAuth::Consumer.new(
      Api::Application.config.twitter_app[:id],
      Api::Application.config.twitter_app[:secret],
      {
        site: 'https://api.twitter.com',
        scheme: :header,
        http_methods: :post,
        authorize_path: '/oauth/authenticate'
      }
    )
  end
end
