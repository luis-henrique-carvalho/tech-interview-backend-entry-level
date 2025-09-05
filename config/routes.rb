require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  resource :carts, only: [:show, :create], controller: 'carts' do
    post :add_item, on: :collection

    delete ':product_id', to: 'carts#remove_item', as: :remove_item
  end

  root "rails/health#show"
end
