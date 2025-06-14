class CreateBattleDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :battle_details do |t|
      t.integer :room_id
      t.text :player_id
      t.boolean :is_win
      t.integer :score
      t.timestamp :joined_at

      t.timestamps
    end
  end
end
