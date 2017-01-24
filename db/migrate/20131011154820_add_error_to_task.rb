class AddErrorToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :error, :boolean, default: false
  end
end
