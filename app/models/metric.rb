class Metric < ActiveRecord::Base
  include Metrics::ModelHelper
  
  serialize :value, JSON
  
  belongs_to :resource
end