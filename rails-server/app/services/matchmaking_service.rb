require 'ostruct'

class MatchmakingService
  QUEUE_KEY = 'matchmaking:queue'
  MATCHED_PAIRS_KEY = 'matchmaking:matched_pairs'
  PLAYER_STATUS_KEY = 'matchmaking:player_status'

  def self.join_queue(player_id)
    # プレイヤーをキューに追加
    $redis.multi do |redis|
      redis.lpush(QUEUE_KEY, player_id)
      redis.hset(PLAYER_STATUS_KEY, player_id, 'waiting')
    end
    
    Rails.logger.info "Player #{player_id} joined matchmaking queue"
  end

  def self.process_queue
    # キューからマッチングを試行
    attempt_matching
  end

  def self.leave_queue(player_id)
    # プレイヤーをキューから削除
    $redis.multi do |redis|
      redis.lrem(QUEUE_KEY, 0, player_id)
      redis.hdel(PLAYER_STATUS_KEY, player_id)
    end
    
    Rails.logger.info "Player #{player_id} left matchmaking queue"
  end

  def self.get_player_status(player_id)
    status = $redis.hget(PLAYER_STATUS_KEY, player_id)
    
    case status
    when 'waiting'
      position = get_queue_position(player_id)
      {
        matched: false,
        waiting: true,
        queue_position: position,
        estimated_wait_time: calculate_wait_time(position)
      }
    when 'matched'
      # マッチしたルームIDを取得
      room_id = $redis.hget("#{MATCHED_PAIRS_KEY}:#{player_id}", 'room_id')
      {
        matched: true,
        roomId: room_id,
        message: "マッチングが成立しました！"
      }
    else
      {
        matched: false,
        waiting: false,
        message: "キューに参加していません"
      }
    end
  end

  def self.attempt_matching
    Rails.logger.info "Attempting to match players..."
    
    # キューの長さを確認
    queue_length = $redis.llen(QUEUE_KEY)
    Rails.logger.info "Queue length: #{queue_length}"
    
    if queue_length >= 2
      # キューから先頭2名を取得（削除も同時に行う）
      player1 = $redis.rpop(QUEUE_KEY)  # 最初に追加されたプレイヤー
      player2 = $redis.rpop(QUEUE_KEY)  # 2番目に追加されたプレイヤー
      
      Rails.logger.info "Players from queue: #{player1}, #{player2}"
      
      if player1 && player2
        # ルームを作成
        room = create_match_room(player1, player2)
        
        Rails.logger.info "Created room: #{room.id} for players #{player1} and #{player2}"
        
        # プレイヤーステータスを更新
        $redis.multi do |redis|
          redis.hset(PLAYER_STATUS_KEY, player1, 'matched')
          redis.hset(PLAYER_STATUS_KEY, player2, 'matched')
          redis.hset("#{MATCHED_PAIRS_KEY}:#{player1}", 'room_id', room.id)
          redis.hset("#{MATCHED_PAIRS_KEY}:#{player2}", 'room_id', room.id)
          redis.hset("#{MATCHED_PAIRS_KEY}:#{player1}", 'opponent', player2)
          redis.hset("#{MATCHED_PAIRS_KEY}:#{player2}", 'opponent', player1)
        end
        
        Rails.logger.info "Matched players #{player1} and #{player2} in room #{room.id}"
        return room
      else
        Rails.logger.info "Failed to get both players from queue"
      end
    else
      Rails.logger.info "Not enough players to match (queue length: #{queue_length})"
    end
    
    nil
  end

  private

  def self.get_queue_position(player_id)
    queue = $redis.lrange(QUEUE_KEY, 0, -1)
    position = queue.index(player_id)
    position ? position + 1 : 0
  end

  def self.calculate_wait_time(position)
    # 簡単な待機時間計算（実際はより複雑な計算が必要）
    [position * 10, 5].max
  end

  def self.create_match_room(player1_id, player2_id)
    room = Room.create!(
      player1_id: player1_id,
      player2_id: player2_id,
      status: 'waiting'
    )
    
    Rails.logger.info "Created room with database ID: #{room.id} for players #{player1_id} and #{player2_id}"
    
    # データベースのIDをそのまま使用（整合性を保つため）
    room
  end
end
