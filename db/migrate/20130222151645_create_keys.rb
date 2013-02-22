class CreateKeys < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.string :name
      t.text :body

      t.timestamps
    end
  end
end
