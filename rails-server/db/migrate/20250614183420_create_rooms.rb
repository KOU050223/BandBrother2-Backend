class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :status, default: 'waiting'
      t.text :player1_id
      t.string :player2_id
      t.integer :music_id
      t.text :winner_user_id
      t.timestamp :started_at
      t.timestamp :ended_at
      t.integer :player1_score, default: 0
      t.integer :player2_score, default: 0
      t.string :player1_difficulty, default: 'Easy'
      t.string :player2_difficulty, default: 'Easy'
      
      t.timestamps
    end
    
    add_index :rooms, :status
    add_index :rooms, [:player1_id, :player2_id]
  end
end
