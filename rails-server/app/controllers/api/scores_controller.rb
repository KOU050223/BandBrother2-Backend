class Api::ScoresController < Api::BaseController
  def create
    firebase_uid = params[:uid]
    room_id = params[:room_id]
    score = params[:score]
    is_win = params[:is_win]
    
    Rails.logger.info "スコア登録開始 - UID: #{firebase_uid}, Room: #{room_id}, Score: #{score}, Win: #{is_win}"

    # BattleDetailレコードを作成または更新（重複防止）
    battle_detail = BattleDetail.find_or_create_by(
      room_id: room_id,
      player_id: firebase_uid
    ) do |bd|
      bd.is_win = is_win
      bd.score = score
    end

    # 既存レコードの場合は更新
    if battle_detail.persisted? && !battle_detail.previously_new_record?
      battle_detail.update(is_win: is_win, score: score)
      Rails.logger.info "既存戦績を更新: #{firebase_uid} - Room: #{room_id}"
    end

    if battle_detail.persisted?
      # ユーザーのハイスコア更新処理
      user = User.find_or_initialize_by(user_id: firebase_uid) do |u|
        u.user_name = "Player#{firebase_uid[0..7]}" # デフォルトユーザー名
        u.highscore = 0
      end
      
      Rails.logger.info "ユーザー検索/作成: #{firebase_uid}, 既存ハイスコア: #{user.highscore || 0}, 新スコア: #{score}"
      
      # 現在のハイスコアより高い場合のみ更新
      highscore_updated = false
      current_highscore = user.highscore || 0
      
      if score > current_highscore
        old_highscore = user.highscore
        user.highscore = score
        
        if user.save
          highscore_updated = true
          Rails.logger.info "ハイスコア更新成功: #{firebase_uid} - #{old_highscore || 0} → #{score}"
        else
          Rails.logger.error "ハイスコア更新失敗: #{firebase_uid} - #{user.errors.full_messages}"
        end
      else
        Rails.logger.info "ハイスコア更新不要: #{firebase_uid} - 現在: #{current_highscore}, 新: #{score}"
      end

      render json: { 
        message: "スコア送信完了！", 
        highscore_updated: highscore_updated, 
        current_highscore: user.highscore,
        battle_detail_id: battle_detail.id
      }
    else
      Rails.logger.error "BattleDetail作成失敗: #{battle_detail.errors.full_messages}"
      render json: { error: "スコア登録に失敗しました", details: battle_detail.errors.full_messages }, status: :unprocessable_entity
    end
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
