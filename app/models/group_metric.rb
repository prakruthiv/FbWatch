class GroupMetric < ActiveRecord::Base
  include Metrics::ModelHelper
  
  serialize :value, JSON

  belongs_to :resource
  belongs_to :resource_group

  has_and_belongs_to_many :resources, -> { order(username: :desc) }

  def klass
    super do |options|
      options[:resource_group] = self.resource_group
    end
  end

  def vars_for_render
    {
      involved_resources: self.resources.to_a.dup,
      owner: self.resource
    }.merge(super)
  end

  def self_referencing?
    self.resource == self.resources.first and self.resources.length == 1
  end
end
