class ApiController < ApplicationController
  # allow JSONP callback parameter
  around_filter :response_to_jsonp

  # find person and update them
  before_filter :find_person
  after_filter :update_person_last_seen_at

  class UnauthorizedError < StandardError; end

  class MissingRequiredParams < StandardError
    attr_accessor :params
    def initialize(*params)
      @params = params
    end
  end

protected

  def response_to_jsonp
    yield
  rescue UnauthorizedError
    render json: { error: "Invalid or missing access token" }, status: :unauthorized
  rescue MissingRequiredParams => e
    render json: { error: "Missing required fields: #{e.params.map(&:to_s).map(&:humanize).join(', ')}", params: e.params }, status: :unprocessable_entity
  ensure
    if params[:callback] =~ /[\w.\[\]\$]+/
      response.content_type = 'application/javascript'
      response.body = "#{params[:callback]}(#{{
        data: (JSON.parse(response.body) rescue nil),
        meta: {
          status:     response.status,
          success:    (200...300).include?(response.status.to_i),
          pagination: (JSON.parse(response.headers['Pagination']) rescue nil)
        }
      }.to_json})"
      response.status = :ok # since !200 breaks JSONP
    end
  end

  def require_params(*keys)
    missing_params = keys.reject { |k| params.has_key?(k) && !params[k].blank? }
    raise MissingRequiredParams.new missing_params unless missing_params.empty?
  end

  def require_auth
    raise UnauthorizedError unless @person
  end

  def find_person
    @person ||= if !params[:access_token].blank?
      Person.find_by_access_token(params[:access_token])
    elsif !params[:email].blank? && !params[:password].blank?
      Person.authenticate(params[:email], params[:password])
    end
  end

  def update_person_last_seen_at
    @person.was_seen! if @person
  end
end