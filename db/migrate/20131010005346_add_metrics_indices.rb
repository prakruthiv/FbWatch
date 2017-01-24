class AddMetricsIndices < ActiveRecord::Migration
  def change
    add_index :likes, :feed_id
    add_index :likes, :resource_id

    add_index :feeds, :from_id
    add_index :feeds, :to_id
    add_index :feeds, :resource_id
    add_index :feeds, :parent_id

    add_index :basicdata, :resource_id

    add_index :feed_tags, :resource_id
    add_index :feed_tags, :feed_id

    add_index :group_metrics, :resource_group_id

    add_index :metrics, :resource_id

    add_index :tasks, :resource_id
    add_index :tasks, :resource_group_id
  end
end
