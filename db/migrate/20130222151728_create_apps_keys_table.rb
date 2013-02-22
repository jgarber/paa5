class CreateAppsKeysTable < ActiveRecord::Migration
  def self.up
    create_table :apps_keys, :id => false do |t|
        t.references :app
        t.references :key
    end
    add_index :apps_keys, [:app_id, :key_id]
    add_index :apps_keys, [:key_id, :app_id]
  end

  def self.down
    drop_table :apps_keys
  end
end
