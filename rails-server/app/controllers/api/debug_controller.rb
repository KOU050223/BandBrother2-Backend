module Api
  class DebugController < Api::BaseController
    def queue_status
      queue_data = {
        queue_length: $redis.llen(MatchmakingService::QUEUE_KEY),
        queue_players: $redis.lrange(MatchmakingService::QUEUE_KEY, 0, -1),
        player_statuses: $redis.hgetall(MatchmakingService::PLAYER_STATUS_KEY),
        matched_pairs_keys: $redis.keys("#{MatchmakingService::MATCHED_PAIRS_KEY}:*")
      }
      
      render json: queue_data
    end

    def clear_queue
      # すべてのマッチメイキング関連データをクリア
      $redis.del(MatchmakingService::QUEUE_KEY)
      $redis.del(MatchmakingService::PLAYER_STATUS_KEY)
      
      # マッチペアのキーも削除
      matched_keys = $redis.keys("#{MatchmakingService::MATCHED_PAIRS_KEY}:*")
      $redis.del(*matched_keys) if matched_keys.any?
      
      Rails.logger.info "Cleared all matchmaking data"
      
      render json: { 
        success: true,
        message: "キューをクリアしました",
        cleared_keys: matched_keys.length
      }
    end

    def process_queue
      # 手動でマッチング処理を実行
      result = MatchmakingService.process_queue
      
      if result
        render json: {
          success: true,
          message: "マッチングが成立しました",
          room_id: result.id
        }
      else
        render json: {
          success: false,
          message: "マッチング可能なプレイヤーが不足しています",
          queue_length: $redis.llen(MatchmakingService::QUEUE_KEY)
        }
      end
    end

    def sync_queue
      # player_statusesでwaitingのプレイヤーを取得
      all_statuses = $redis.hgetall(MatchmakingService::PLAYER_STATUS_KEY)
      waiting_players = all_statuses.select { |player_id, status| status == 'waiting' }.keys
      
      # 現在のキューをクリア
      $redis.del(MatchmakingService::QUEUE_KEY)
      
      # waitingステータスのプレイヤーをキューに再追加
      waiting_players.each do |player_id|
        $redis.lpush(MatchmakingService::QUEUE_KEY, player_id)
      end
      
      Rails.logger.info "Synchronized queue with #{waiting_players.length} waiting players"
      
      render json: {
        success: true,
        message: "キューを同期しました",
        synchronized_players: waiting_players,
        queue_length: waiting_players.length
      }
    end

    def sync_rooms
      # データベースのルームをRedisと同期
      rooms = Room.where(status: 'waiting')
      synced_count = 0
      
      rooms.each do |room|
        player1_id = room.player1_id
        player2_id = room.player2_id
        
        # プレイヤーステータスを更新
        $redis.multi do |redis|
          redis.hset(MatchmakingService::PLAYER_STATUS_KEY, player1_id, 'matched')
          redis.hset(MatchmakingService::PLAYER_STATUS_KEY, player2_id, 'matched')
          redis.hset("#{MatchmakingService::MATCHED_PAIRS_KEY}:#{player1_id}", 'room_id', room.id)
          redis.hset("#{MatchmakingService::MATCHED_PAIRS_KEY}:#{player2_id}", 'room_id', room.id)
          redis.hset("#{MatchmakingService::MATCHED_PAIRS_KEY}:#{player1_id}", 'opponent', player2_id)
          redis.hset("#{MatchmakingService::MATCHED_PAIRS_KEY}:#{player2_id}", 'opponent', player1_id)
        end
        
        # キューから削除
        $redis.lrem(MatchmakingService::QUEUE_KEY, 0, player1_id)
        $redis.lrem(MatchmakingService::QUEUE_KEY, 0, player2_id)
        
        synced_count += 1
        Rails.logger.info "Synced room #{room.id} with players #{player1_id} and #{player2_id}"
      end
      
      render json: {
        success: true,
        message: "ルームとRedisを同期しました",
        synced_rooms: synced_count,
        rooms: rooms.map { |r| { id: r.id, player1: r.player1_id, player2: r.player2_id } }
      }
    end
  end
end