class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :facebook_id
      t.text :data
      t.string :data_type
      t.string :feed_type
      t.datetime :created_time
      t.datetime :updated_time
      t.integer :likes
      t.integer :comments
      
      t.belongs_to :resource
      t.belongs_to :from
      t.belongs_to :to

      t.timestamps
    end
  end
end
