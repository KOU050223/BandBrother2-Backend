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
      
      # POSTリクエストの場合はキューに参加
      if request.post?
        MatchmakingService.join_queue(player_id)
        MatchmakingService.process_queue
      end
      
      # マッチングサービスからプレイヤーステータスを取得
      status = MatchmakingService.get_player_status(player_id)
      
      render json: status
    end
  end
end
