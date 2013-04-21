Santim::Application.routes.draw do
  root :to => "frontend#index"

  namespace :api do
    resource :user, only: [:show, :create, :update] do
      collection do
        post :reset_password
        post :change_password
        post :request_password_reset
        post :login
      end
    end
  end
end
