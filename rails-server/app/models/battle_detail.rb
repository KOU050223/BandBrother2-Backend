class BattleDetail < ApplicationRecord
  # バリデーション
  validates :room_id, presence: true
  validates :player_id, presence: true
  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_win, inclusion: { in: [true, false] }

  # 関連付け
  belongs_to :room, foreign_key: 'room_id', primary_key: 'id', optional: true

  # スコープ
  scope :winners, -> { where(is_win: true) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }
end
