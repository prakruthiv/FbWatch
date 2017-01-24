class CreateResourceGroups < ActiveRecord::Migration
  def change
    create_table :resource_groups do |t|
      t.string :group_name
    end

    create_table :resource_groups_resources, id: false do |t|
      t.belongs_to :resource
      t.belongs_to :resource_group
    end

    add_index :resource_groups_resources, [:resource_id, :resource_group_id], unique: true, name: 'index_resource_groups_resources_on_resource_and_resource_group'
    add_index :resource_groups_resources, :resource_id
    add_index :resource_groups_resources, :resource_group_id
  end
end
