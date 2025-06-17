class Room < ApplicationRecord
  validates :status, inclusion: { in: %w[waiting ready playing finished] }
  validates :player1_id, presence: true
  # 一時的にdifficultyバリデーションを無効化
  # validates :player1_difficulty, :player2_difficulty, inclusion: { in: %w[Easy Normal Hard] }, allow_nil: true

  scope :waiting, -> { where(status: 'waiting') }
  scope :ready, -> { where(status: 'ready') }
  scope :playing, -> { where(status: 'playing') }

  def full?
    player1_id.present? && player2_id.present?
  end

  def waiting_for_players?
    status == 'waiting' && !full?
  end

  def ready_to_start?
    status == 'ready' && full?
  end

  def winner
    return nil unless finished?
    return 'tie' if player1_score == player2_score
    
    player1_score > player2_score ? player1_id : player2_id
  end

  def finished?
    status == 'finished'
  end
end
