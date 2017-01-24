class A < ActiveRecord::Migration
  def change
    rename_column :feeds, :comments, :comment_count
    rename_column :feeds, :likes, :like_count
  end
end
