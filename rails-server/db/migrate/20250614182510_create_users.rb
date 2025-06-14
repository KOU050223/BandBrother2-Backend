class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.text :user_id
      t.string :user_name
      t.integer :highscore

      t.timestamps
    end
  end
end
