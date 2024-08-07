Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"
  resources :notes do
    resources :comments
  end
  get '/notes/list', to: 'notes#list'


  get 'bible_verses/books', to: 'bible_verses#book_index'
  Rails.application.routes.draw do
    devise_for :users, controllers: {
      sessions: 'users/sessions'
    }
  end
end
