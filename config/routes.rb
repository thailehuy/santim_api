Santim::Application.routes.draw do
  devise_for :users

  root :to => "frontend#index"
end
