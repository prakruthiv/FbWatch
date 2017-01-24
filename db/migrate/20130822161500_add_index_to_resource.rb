class AddIndexToResource < ActiveRecord::Migration
  def change
    add_index :resources, :facebook_id
  end
end
