Paa5::Application.routes.draw do
  resources :apps


  root :to => "home#index"
end
