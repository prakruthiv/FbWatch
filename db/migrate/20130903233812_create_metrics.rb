class CreateMetrics < ActiveRecord::Migration
  def change
    create_table :metrics do |t|
      t.string :metric_id
      t.string :name
      t.string :description
      t.string :value

      t.belongs_to :resource

      t.timestamps
    end
  end
end
