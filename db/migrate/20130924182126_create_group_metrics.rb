class CreateGroupMetrics < ActiveRecord::Migration
  def change
    create_table :group_metrics do |t|
      t.string :metric_class
      t.string :resources_token
      t.string :name
      t.text :value

      t.belongs_to :resource_group

      t.timestamps
    end

    create_table :group_metrics_resources, id: false do |t|
      t.belongs_to :group_metric
      t.belongs_to :resource
    end

    add_index :group_metrics_resources, [:resource_id, :group_metric_id], unique: true, name: 'index_group_metrics_resources_on_resource_and_group_metric'
    add_index :group_metrics_resources, :resource_id
    add_index :group_metrics_resources, :group_metric_id
  end
end
