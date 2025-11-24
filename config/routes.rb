Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"
  
  get '/notes/list', to: 'notes#list'
  
  # Bible verses=
  get 'bible_verses/books', to: 'bible_verses#book_index'
  get 'bible_verses/verse_picker', to: 'bible_verses#verse_picker', as: :bible_verse_picker
  get 'bible_verses/:book/chapters', to: 'bible_verses#chapters', as: :bible_verse_chapters
  get 'bible_verses/:book/:chapter', to: 'bible_verses#verses', as: :bible_verse_verses
  get 'bible_verses/:book/:chapter/:verse', to: 'bible_verses#show', as: :bible_verse_show
  get 'bible_verses/:book/:chapter/:verse/comments/new', to: 'comments#new', as: :new_bible_verse_comment
  post 'bible_verses/:book/:chapter/:verse/comments', to: 'comments#create', as: :bible_verse_comments
  get 'bible_verses/:book/:chapter/:verse/comments/:id/edit', to: 'comments#edit', as: :edit_bible_verse_comment
  patch 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#update', as: :bible_verse_comment
  put 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#update'
  delete 'bible_verses/:book/:chapter/:verse/comments/:id', to: 'comments#destroy'
  
  # Cross-references routes
  get 'bible_verses/:source_book/:source_chapter/:source_verse/cross_references/new', to: 'cross_references#new', as: :new_bible_verse_cross_reference
  post 'bible_verses/:source_book/:source_chapter/:source_verse/cross_references', to: 'cross_references#create', as: :bible_verse_cross_references
  delete 'cross_references/:id', to: 'cross_references#destroy', as: :cross_reference
  
  # Bible threads routes
  resources :bible_threads
  
  # Comments on cross-references
  
  # Individual comment management
  get 'comments/:id/edit', to: 'comments#edit', as: :edit_comment
  patch 'comments/:id', to: 'comments#update', as: :comment
  delete 'comments/:id', to: 'comments#destroy'
  
  # Notes routes
  resources :notes do
    member do
      patch :publish
      patch :unpublish
    end
    collection do
      get :drafts
    end
    resources :comments, only: [:new, :create, :edit, :update, :destroy]
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  
  # OTP/2FA routes
  namespace :users do
    get 'otp/verify', to: 'otp_sessions#new', as: :otp_verify
    post 'otp/verify', to: 'otp_sessions#create'
    post 'otp/resend', to: 'otp_sessions#resend', as: :otp_resend
    patch 'two_factor_settings', to: 'two_factor_settings#update', as: :two_factor_settings
  end
  
  # Onboarding routes
  get 'onboarding', to: 'onboarding#show', as: :onboarding
  post 'onboarding/complete', to: 'onboarding#complete', as: :complete_onboarding
  post 'onboarding/skip', to: 'onboarding#skip', as: :skip_onboarding
  
  # Content flagging routes
  resources :content_flags, only: [:create]
  get 'my-flagged-content', to: 'my_flagged_content#index', as: :my_flagged_content
  
  # Admin routes
  namespace :admin do
    resources :users, only: [:index, :edit, :update, :destroy]
    resources :content_flags, only: [:index] do
      member do
        patch :approve
        patch :request_review
        get :edit_content
        delete :destroy_content
      end
    end
  end
end