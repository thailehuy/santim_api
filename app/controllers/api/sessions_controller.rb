class Api::SessionController < ApplicationController

  WHITELISTED_REDIRECT_URL = /^https?:\/\/(www|api)(-qa)?\.bountysource\.(com|dev)\//

  # get an oauth code, which is exchanged for an access_token in #callback
  def login
    case params[:provider]
      when 'facebook'
        redirect_to LinkedAccount::Facebook.oauth_url(
                      scope:  params[:scope],
                      state:  { redirect_url: params[:redirect_url], access_token: params[:access_token] }
                    )

      when 'twitter'
        @request_token = LinkedAccount::Twitter.oauth_consumer.get_request_token(
          oauth_callback: "#{Api::Application.config.api_url}auth/twitter/callback",
          state:          { redirect_url: params[:redirect_url], access_token: params[:access_token] }
        )
        session[:twitter_request_token] = @request_token
        redirect_to @request_token.authorize_url

      else render json: { error: 'Unsupported provider' }, status: :bad_request
    end
  end

  # exchange an Oauth code for access_token. auto-create an account if necessary, and return
  # to frontend with account_link info.
  def callback
    # first, load the state (redirect_url, access_token)
    state = params[:state] ? JSON.parse(params[:state]).with_indifferent_access : {}

    # set @linked_account, @redirect_url, and optionally @user
    case params[:provider]
      when 'facebook'
        @linked_account = LinkedAccount::Facebook.find_or_create_via_oauth_code params[:code]
        @user         = User.find_by_access_token(state[:access_token])
        @redirect_url   = state[:redirect_url]

      when 'twitter'
        @linked_account = LinkedAccount::Twitter.find_or_create_via_request_token session[:twitter_request_token]
        @user         = User.find_by_access_token(state[:access_token])
        @redirect_url   = state[:redirect_url]
    end

    # run through all of the use cases
    if @user && (@user == @linked_account.user)
      # nothing to do... @user is already logged in and linked to this account.
      opts = { status: 'linked', access_token: @user.create_access_token }
    elsif @user && !@linked_account.user
      # should be safe to link this account to the logged in @user
      @linked_account.update_attributes(user: @user)
      opts = { status: 'linked', access_token: @user.create_access_token }
    elsif @user
      # error! @user logged in but not the same as @linked_account.user
      opts = { status: 'error_already_linked' }
    elsif @linked_account.user
      # user not logged in but exists... aka single-sign-on
      opts = { status: 'linked', access_token: @linked_account.user.create_access_token }
    else
      # nobody logged in, and no user on this account... they need to create an account
      opts = {
        status:               'error_needs_account',
        email_is_registered:  !!User.find_by_email(@linked_account.email),
        account_link_id:      "#{params[:provider]}:#{@linked_account.create_access_token}",
        first_name:           @linked_account.first_name,
        last_name:            @linked_account.last_name,
        email:                @linked_account.email,
        avatar_url:           @linked_account.avatar_url,
        display_name:         @linked_account.login
      }
    end

    # redirect, should be provider-agnostic
    @redirect_url ||= Api::Application.config.www_url
    raise MissingRequiredParams, :redirect_url unless @redirect_url =~ WHITELISTED_REDIRECT_URL

    # merge redirect URL
    opts.merge! redirect_url: @redirect_url

    redirect_to "#{Api::Application.config.www_url}#auth/#{params[:provider]}?#{opts.to_param}"
  end
end
