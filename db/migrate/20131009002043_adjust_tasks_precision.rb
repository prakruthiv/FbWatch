class AdjustTasksPrecision < ActiveRecord::Migration
  def change
    change_column :tasks, :progress, :decimal, precision: 3, scale: 2
  end
end
