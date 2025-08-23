Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"

  get '/notes/list', to: 'notes#list'
  get 'bible_verses/books', to: 'bible_verses#book_index'
  get 'bible_verses/:book/chapters', to: 'bible_verses#chapters', as: :bible_verse_chapters
  get 'bible_verses/:book/:chapter', to: 'bible_verses#verses', as: :bible_verse_verses
  get 'bible_verses/:book/:chapter/:verse', to: 'bible_verses#show', as: :bible_verse_show
  get 'bible_verses/:book/:chapter/:verse/comments/new', to: 'comments#new', as: :new_bible_verse_comment
  post 'bible_verses/:book/:chapter/:verse/comments', to: 'comments#create', as: :bible_verse_comments
  get 'bible_verses/:book/:chapter/:verse/comments/:id/edit', to: 'comments#edit', as: :edit_bible_verse_comment
  patch 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#update', as: :bible_verse_comment
  put 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#update'
  delete 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#destroy'
  
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