class CreateFeedTags < ActiveRecord::Migration
  def change
    create_table :feed_tags do |t|
      t.belongs_to :feed
      t.belongs_to :resource
    end
  end
end
