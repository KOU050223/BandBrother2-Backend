class RemoveDuplicateBattleDetails < ActiveRecord::Migration[8.0]
  def up
    # 重複するレコードを削除（最新のもの以外）
    execute <<-SQL
      DELETE FROM battle_details 
      WHERE id NOT IN (
        SELECT MAX(id) 
        FROM battle_details 
        GROUP BY room_id, player_id
      );
    SQL
    
    # ユニークインデックスを追加
    add_index :battle_details, [:room_id, :player_id], unique: true
  end
  
  def down
    remove_index :battle_details, [:room_id, :player_id]
  end
end
