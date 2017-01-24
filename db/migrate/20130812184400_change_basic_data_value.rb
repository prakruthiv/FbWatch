class ChangeBasicDataValue < ActiveRecord::Migration
  def change
    change_column :basicdata, :value, :text
  end
end
