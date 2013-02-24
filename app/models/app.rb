class App < ActiveRecord::Base
  attr_accessible :domains, :name, :key_ids
  attr_readonly :name

  validates :name, uniqueness: true, format: {with: /^[a-z0-9-]+$/i, message: "Must be a valid git repo name" }
  has_and_belongs_to_many :keys

  after_create do
    GitShell.new(name).create_app
  end

  def push_url
    if keys.any?
      "#{name}.git"
    else
      "Add a public key to push to this repository"
    end
  end
end
