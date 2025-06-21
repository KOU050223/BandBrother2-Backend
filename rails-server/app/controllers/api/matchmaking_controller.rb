module Api
  class MatchmakingController < Api::BaseController

    def join
      # プレイヤーIDを生成（実際にはユーザー認証から取得）
      player_id = params[:player_id] || SecureRandom.uuid
      
      # マッチングキューに参加
      MatchmakingService.join_queue(player_id)
      
      render json: { 
        status: "ok",
        player_id: player_id,
        message: "マッチングキューに参加しました",
        websocket_url: "ws://localhost:8080/ws"
      }
    end

    def destroy
      # プレイヤーIDを取得
      player_id = params[:player_id]
      
      if player_id
        # マッチングキューから離脱
        MatchmakingService.leave_queue(player_id)
        render json: { status: "left", message: "マッチングキューから離脱しました" }
      else
        render json: { status: "error", message: "プレイヤーIDが必要です" }, status: :bad_request
      end
    end

    def status
      # ルームのステータスを返す
      room_id = params[:room_id]
      room = Room.find_by(id: room_id)
      
      if room
        render json: { 
          room_id: room_id,
          status: room.status,
          player1_id: room.player1_id,
          player2_id: room.player2_id,
          players_count: room.full? ? 2 : 1
        }
      else
        render json: { error: "ルームが見つかりません" }, status: :not_found
      end
    end

    def debug_redis
      # Redis接続確認とキー一覧
      begin
        redis = Redis.new
        keys = redis.keys("*")
        info = {
          redis_connected: true,
          total_keys: keys.length,
          keys: keys.first(20), # 最初の20キーのみ表示
          queue_keys: keys.select { |k| k.include?("queue") || k.include?("match") }
        }
        
        # キューの内容確認
        if redis.exists?("matchmaking_queue")
          info[:queue_length] = redis.llen("matchmaking_queue")
          info[:queue_contents] = redis.lrange("matchmaking_queue", 0, -1)
        end
        
        render json: info
      rescue => e
        render json: { 
          redis_connected: false, 
          error: e.message,
          redis_url: ENV['REDIS_URL']
        }
      end
    end
  end
end
