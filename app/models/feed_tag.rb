class FeedTag < ActiveRecord::Base
  belongs_to :feed
  belongs_to :resource

  def to_fb_hash
    self.resource.to_fb_hash
  end
end
