Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  root 'weather_forecasts#index'
  
  resources :weather_forecasts do
    collection do
      get :search
      post :search
      get :api_search
    end
  end
  
  # API routes for potential future expansion
  namespace :api do
    namespace :v1 do
      resources :weather_forecasts, only: [:show]
    end
  end
end
