module Api
  class MatchNotificationController < Api::BaseController
    def notify_match
      # プレイヤーIDを取得
      player_id = params[:player_id]
      
      if player_id.blank?
        render json: { 
          matched: false,
          error: "プレイヤーIDが必要です" 
        }, status: :bad_request
        return
      end
      
      # POSTリクエストの場合はキューに参加（一時的にRedis無しでテスト）
      if request.post?
        Rails.logger.info "Player #{player_id} joined matchmaking queue - BYPASSING REDIS"
        # 一時的な成功レスポンス（Redis完全バイパス版）
        status = { 
          matched: false, 
          message: "マッチングキューに参加しました。対戦相手を探しています...",
          player_id: player_id,
          queue_position: 1
        }
      else
        # GETリクエストの場合（ポーリング）
        Rails.logger.info "Polling status for player #{player_id}"
        status = { 
          matched: false, 
          message: "対戦相手を探しています...",
          player_id: player_id,
          queue_position: 1
        }
      end
      
      render json: status
    end

    def cancel_match
      # プレイヤーIDを取得
      player_id = params[:player_id]
      
      if player_id.blank?
        render json: { 
          success: false,
          error: "プレイヤーIDが必要です" 
        }, status: :bad_request
        return
      end
      
      # マッチングキューからプレイヤーを削除（Redis無しでテスト用）
      # MatchmakingService.leave_queue(player_id)  # 一時的にコメントアウト
      
      Rails.logger.info "Player #{player_id} cancelled matchmaking"
      
      render json: { 
        success: true,
        message: "マッチングをキャンセルしました" 
      }
    end
  end
end
