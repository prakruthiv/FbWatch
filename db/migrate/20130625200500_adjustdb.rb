class Adjustdb < ActiveRecord::Migration
  def change
    # change basicdata
    remove_column :basicdata, :name
    remove_column :basicdata, :first_name
    remove_column :basicdata, :last_name
    remove_column :basicdata, :link
    remove_column :basicdata, :username
    remove_column :basicdata, :hometown_id
    remove_column :basicdata, :hometown
    remove_column :basicdata, :location_id
    remove_column :basicdata, :location
    remove_column :basicdata, :gender
    remove_column :basicdata, :email
    remove_column :basicdata, :timezone
    remove_column :basicdata, :locale
    remove_column :basicdata, :verified
    remove_column :basicdata, :updated_time
    
    add_column :basicdata, :key, :string
    add_column :basicdata, :value, :string
    
    # change resource
    add_column :resources, :username, :string
    add_column :resources, :link, :string
    
    add_index :resources, :username, unique: true
  end
end
