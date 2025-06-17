class Api::ScoresController < ActionController::API
  def create
    firebase_uid = params[:uid]
    room_id = params[:room_id]

    user = BattleDetail.create(room_id: params[:room_id] ,player_id: params[:uid],is_win: params[:is_win], score: params[:score] )

      render json:{ message: "スコア送信完了！" }
  end
#ユーザーの戦績取得
  def show
    firebase_uid = params[:uid]
    user = BattleDetail.where(player_id: firebase_uid)
    if user.present?#ユーザーが空かどうか確認
      render json: user
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

end
