class Basicdata < ActiveRecord::Base
#  attr_accessible :key, :value
  serialize :value, JSON
  
  belongs_to :resource
end
