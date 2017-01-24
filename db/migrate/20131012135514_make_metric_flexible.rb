class MakeMetricFlexible < ActiveRecord::Migration
  def change
    remove_column :metrics, :description
    rename_column :metrics, :metric_id, :metric_class
  end
end
