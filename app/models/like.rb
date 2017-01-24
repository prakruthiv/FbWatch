class Like < ActiveRecord::Base
  belongs_to :resource
  belongs_to :feed
  
  def to_fb_hash
    if self.resource.nil?
      Rails.logger.debug('WARN: encountered like with no resource attached: ' + self.id.to_s)
      return nil
    end
    
    self.resource.to_fb_hash
  end
end
