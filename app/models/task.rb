class Task < ActiveRecord::Base
  serialize :data, JSON

  belongs_to :resource
  belongs_to :resource_group

  # not actually using this but type column is usually reserved for inheritance
  @inheritance_column = 'class_type'

  def real_duration
    return self.duration unless self.running

    self.duration + (Time.now - self.updated_at)
  end
end
