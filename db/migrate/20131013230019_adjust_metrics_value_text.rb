class AdjustMetricsValueText < ActiveRecord::Migration
  def change
    change_column :metrics, :value, :text
  end
end
