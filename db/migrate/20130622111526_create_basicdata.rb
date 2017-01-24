class CreateBasicdata < ActiveRecord::Migration
  def change
    create_table :basicdata do |t|
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :link
      t.string :username
      t.integer :hometown_id
      t.string :hometown
      t.integer :location_id
      t.string :location
      t.string :gender
      t.string :email
      t.integer :timezone
      t.string :locale
      t.boolean :verified
      t.datetime :updated_time
      t.references :resource

      t.timestamps
    end
  end
end
