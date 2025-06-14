class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :status
      t.text :player1_id
      t.string :player2_id
      t.integer :music_id
      t.text :winner_user_id
      t.timestamp :started_at
    end
  end
end
