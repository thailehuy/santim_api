class LinkedAccount::Facebook < LinkedAccount::Base
  OAUTH_CODE_URL        = "https://www.facebook.com/dialog/oauth"
  API_HOST              = "https://graph.facebook.com/"
  OAUTH_EXCHANGE_URL    = "#{API_HOST}oauth/access_token"
  USER_INFO_URL         = "#{API_HOST}me"

  # create URL for Facebook authentication via oauth
  #
  # http://www.facebook.com/dialog/oauth/?
  #  client_id=YOUR_APP_ID
  #  &redirect_uri=YOUR_REDIRECT_URL
  #  &state=YOUR_STATE_VALUE
  #  &scope=COMMA_SEPARATED_LIST_OF_PERMISSION_NAMES
  def self.oauth_url(options={})
    %(#{OAUTH_CODE_URL}?#{options.merge(
      client_id:      Api::Application.config.facebook_app[:id],
      redirect_uri:   "#{Api::Application.config.api_url}auth/facebook/callback",
      state:          (options[:state].to_json unless options[:state].blank?),
      display:        options[:display] || 'page',
      scope:          options[:scope],
      response_type:  'code'
    ).to_param})
  end

  # https://graph.facebook.com/oauth/access_token?
  #   client_id=YOUR_APP_ID
  #   &redirect_uri=YOUR_URL
  #   &client_secret=YOUR_APP_SECRET
  #   &code=THE_CODE_FROM_ABOVE
  def self.find_or_create_via_oauth_code(code)
    params = {
      client_id:      Api::Application.config.facebook_app[:id],
      client_secret:  Api::Application.config.facebook_app[:secret],
      redirect_uri:   "#{Api::Application.config.api_url}auth/facebook/callback",
      code:           code
    }

    # exchange the code for an access token
    response = with_https "#{OAUTH_EXCHANGE_URL}?#{params.to_param}" do |uri, http|
      request           = Net::HTTP::Get.new(uri.to_s)
      request.add_field "Accept", "application/json"
      http.request      request
    end

    # raise if access_token fetch fails
    unless (200...300).cover? response.code.to_i
      oauth_response = JSON.parse(response.body).with_indifferent_access
      raise OauthError, oauth_response[:error]
    end

    # Facebook Oauth doesn't return the access token in a JSON body,
    # violating the Oauth specs. Grrr. Parse the query string response.
    oauth_response = Rack::Utils.parse_nested_query(response.body).with_indifferent_access

    # get user info
    user_info = with_https "#{USER_INFO_URL}?access_token=#{oauth_response[:access_token]}" do |uri, http|
      request = Net::HTTP::Get.new(uri.to_s)
      JSON.parse(http.request(request).body).with_indifferent_access
    end

    # find or create a facebook linked account
    facebook_account = find_or_create_by_uid(
      uid:        user_info['id'],
      first_name: user_info['first_name'],
      last_name:  user_info['last_name'],
      login:      user_info['username'],
      email:      user_info['email'],
      avatar_url: "https://graph.facebook.com/#{user_info['username']}/picture?width=200&height=200"
    )

    # update the facebook user with most recent access token and avatar_url
    facebook_account.update_attributes oauth_token: oauth_response[:access_token]

    facebook_account
  end

  # make call to the FB API to get the users's friends.
  # returns an array of objects containing the friend's name and (Facebook) ID
  def friends
    return [] if oauth_token.blank?

    self.class.with_https "#{API_HOST}me/friends?#{{ access_token: oauth_token }.to_param}" do |uri, http|
      request = Net::HTTP::Get.new(uri.to_s)
      response = http.request(request)

      if (200...300).cover? response.code.to_i
        JSON.parse(response.body)['data']
      else
        update_attributes(oauth_token: nil) and []
        []
      end
    end
  end
end
