class Api::ScoresController < Api::BaseController
  def create
    firebase_uid = params[:uid]
    room_id = params[:room_id]

    user = BattleDetail.create(room_id: params[:room_id] ,player_id: params[:uid],is_win: params[:is_win], score: params[:score] )

    render json:{ message: "スコア送信完了！" }
  end

#ハイスコア更新処理
  def update
    firebase_uid = params[:uid]
    room_id = params[:room_id]
    score = params[:score]
    is_win = params[:is_win]
    # ユーザーのスコアを更新
    user = BattleDetail.find_or_initialize_by(player_id: firebase_uid, room_id: room_id)
    user.score = score
    user.is_win = is_win
    if user.save
      render json: { message: "スコア更新完了！" }, status: :ok
    else
      render json: { error: "スコア更新に失敗しました", details: user.errors.full_messages }, status: :unprocessable_entity
    end
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
