class App < ActiveRecord::Base
  attr_accessible :domains, :name

  def push_url
    "Add a public key to push to this repository"
  end
end
