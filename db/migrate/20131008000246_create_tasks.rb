class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.belongs_to :resource
      t.belongs_to :resource_group
      t.string :type
      t.decimal :progress, precision: 2, scale: 1
      t.integer :duration
      t.text :data
      t.boolean :running
      t.timestamps
    end
  end
end
