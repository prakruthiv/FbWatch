class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.belongs_to :resource
      t.belongs_to :feed
      
      t.timestamps
    end
  end
end
