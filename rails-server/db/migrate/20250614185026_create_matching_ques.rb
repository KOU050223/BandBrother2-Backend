class CreateMatchingQues < ActiveRecord::Migration[8.0]
  def change
    create_table :matching_ques do |t|
      t.text :user_id
      t.string :status
      t.integer :room_id
      t.timestamp :enqueued_at

      t.timestamps
    end
  end
end
