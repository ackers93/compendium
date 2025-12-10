Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"
  
  get '/notes/list', to: 'notes#list'
  
  # Bible verses=
  get 'bible_verses/books', to: 'bible_verses#book_index'
  get 'bible_verses/verse_picker', to: 'bible_verses#verse_picker', as: :bible_verse_picker
  get 'bible_verses/autocomplete', to: 'bible_verses#autocomplete', as: :bible_verses_autocomplete
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
  
  # Topics routes
  resources :topics, only: [:index, :show] do
    collection do
      get :autocomplete
    end
    member do
      post :add_verse
    end
  end
  post 'topics', to: 'topics#create'
  get 'bible_verses/:book/:chapter/:verse/topics/new', to: 'verse_topics#new', as: :new_bible_verse_topic
  post 'bible_verses/:book/:chapter/:verse/topics', to: 'verse_topics#create', as: :bible_verse_topics
  get 'verse_topics/:id/edit', to: 'verse_topics#edit', as: :edit_verse_topic
  patch 'verse_topics/:id', to: 'verse_topics#update', as: :verse_topic
  put 'verse_topics/:id', to: 'verse_topics#update'
  delete 'verse_topics/:id', to: 'verse_topics#destroy'
  
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
  
  # Search routes
  get 'search', to: 'searches#index', as: :search
  get 'search/topics', to: 'searches#topics', as: :search_topics
  get 'search/threads', to: 'searches#threads', as: :search_threads
  get 'search/notes', to: 'searches#notes', as: :search_notes
  get 'search/verse_comments', to: 'searches#verse_comments', as: :search_verse_comments
  get 'search/cross_reference_comments', to: 'searches#cross_reference_comments', as: :search_cross_reference_comments
  get 'search/note_comments', to: 'searches#note_comments', as: :search_note_comments
  
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
    resources :reviews, only: [:index] do
      delete 'comments/:id', to: 'reviews#destroy_comment', as: :destroy_comment, on: :collection
      delete 'cross_references/:id', to: 'reviews#destroy_cross_reference', as: :destroy_cross_reference, on: :collection
    end
  end
end