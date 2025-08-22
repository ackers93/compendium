Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"

  get '/notes/list', to: 'notes#list'
  get 'bible_verses/books', to: 'bible_verses#book_index'
  
  resources :notes do
    resources :comments, only: [:new, :create, :edit, :update, :destroy]
  end
  
  resources :bible_verses do
    resources :comments, only: [:new, :create, :edit, :update, :destroy]
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
end