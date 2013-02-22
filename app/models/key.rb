class Key < ActiveRecord::Base
  attr_accessible :body, :name
  has_and_belongs_to_many :apps
end
