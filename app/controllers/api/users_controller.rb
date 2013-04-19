class Api::UsersController < ApplicationController
  respond_to :json

  before_filter :require_auth,    only: [:show, :update, :change_password]
  before_filter :require_profile, only: [:profile]

  # show all of the authenticated user's info
  def show
  end

  # get the info needed to show user profile
  def profile
    @fundraisers = @account.fundraisers.published
    render "people/profile"
  end

  def create
    person_params = {
      email:                  params[:email],
      display_name:           params[:display_name],
      first_name:             params[:first_name],
      last_name:              params[:last_name],
      password:               params[:password]
    }

    case params[:account_link_id]
      # Facebook and Twitter
      when /^(facebook|twitter):(.*)$/
        @linked_account = LinkedAccount::Base.find_by_access_token($2)
        raise ActiveRecord::RecordNotFound unless @linked_account && @linked_account.person.nil?

        # create person
        @user = User.create!(person_params.merge(password: "Aa1#{SecureRandom.urlsafe_base64}"))
        # link github account
        @linked_account.link_with_person(@user)

      else
        # normal use case
        @user = User.create!(person_params)
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unable to create account: Invalid account link" }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Unable to create account: #{e.record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
  end

  # login to an existing BountySource account
  def login
    if !(@user = User.find_by_email(params[:email]))
      render json: { error: 'Email address not found.', email_is_registered: false }, status: :not_found
    elsif !@user.authenticate(params[:password])
      render json: { error: 'Password not correct.', email_is_registered: true }, status: :not_found
    else
      case params[:account_link_id]
        when /^(facebook|twitter):(.*)$/

          if !(linked_account = LinkedAccount::Base.find_by_access_token($2))
            render json: { error: "Unable to find #{$1.capitalize} user", email_is_registered: true }, status: :not_found
          elsif linked_account.person
            render json: { error: "#{$1.capitalize} account already linked", email_is_registered: true }, status: :not_found
          else
            linked_account.link_with_person @user
          end

        else
          # normal login
      end

    end
  end

  # update the BountySource account
  def update
    @user.update_attributes!({
      email:                  params[:email],
      display_name:           params[:display_name],
      first_name:             params[:first_name],
      last_name:              params[:last_name],
      password:               params[:password]
    }.reject { |k,v| v.blank? })
    render "users/show"
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Unable to update account: #{e.record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
  end

  # change the authenticated user's password
  def change_password
    require_params(:current_password, :new_password, :password_confirmation)

    if @user.authenticate(params[:current_password])
      @user.password = params[:new_password]
      @user.password_confirmation = params[:password_confirmation]

      if @user.save
        render "users/show"
      else
        render json: { error: "Unable to change password: #{@user.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Current password not correct' }, status: :unauthorized
    end
  end

  def reset_password
    require_params(:email, :code, :new_password)

    if params[:email].blank?
      render json: { error: 'Must provide account email address or display name' }, status: :bad_request
    elsif (person = User.find_by_email(params[:email]))
      if person.reset_password_code == params[:code]
        person.password = params[:new_password]

        if person.save
          render json: { message: 'Password reset' }, status: :reset_content
        else
          render json: { error: "Unable to reset password: #{person.errors.full_messages.join(', ')}" }, status: :bad_request
        end
      else
        render json: { error: 'Reset code is not valid' }, status: :bad_request
      end
    else
      render json: { message: 'Account not found' }, status: :not_found
    end
  end

  def request_password_reset
    require_params(:email)

    if (person = User.find_by_email(params[:email]))
      person.send_email(:reset_password)
      render json: { message: 'Password reset email sent' }
    else
      render json: { error: 'Account not found' }, status: :not_found
    end
  end

protected

  def require_profile
    unless (@account = User.find_by_id(params[:profile_id]))
      render json: { error: 'Profile not found' }, status: :not_found
    end
  end
end
