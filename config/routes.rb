Paa5::Application.routes.draw do
  resources :keys


  resources :apps


  root :to => "home#index"
end
