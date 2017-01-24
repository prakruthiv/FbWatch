class ImproveGroupMetrics < ActiveRecord::Migration
  def change
    remove_column :group_metrics, :resources_token, :string
    add_reference :group_metrics, :resource, index: true
  end
end
