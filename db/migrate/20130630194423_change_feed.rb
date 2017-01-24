class ChangeFeed < ActiveRecord::Migration
  def change
    add_column :feeds, :parent_id, :integer
  end
end
