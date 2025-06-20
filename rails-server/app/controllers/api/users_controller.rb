class Api::UsersController < ActionController::API
  # ユーザーの新規作成またはログイン
  def create
    firebase_uid = params[:uid]
    user_name = params[:user_name]

    if firebase_uid.blank?
      render json: { error: "UIDが送信されていません" }, status: :bad_request
      return
    end
    # Firebase UIDを使用してユーザーを検索
    # ユーザーが存在する場合はそのユーザーを返し、存在しない場合は新規作成
      user = User.find_by(user_id: firebase_uid)

      if user
        render json:{ message: "ログイン完了！"}
      else
        user = User.create(user_id: firebase_uid, user_name: user_name)
        render json:{ message: "新規作成完了！"}
      end
  end

  # ユーザー情報の更新
  def update
    # ユーザーIDを取得
    firebase_uid = params[:uid]
    # ユーザーを検索
    user = User.find_by(user_id: firebase_uid)

    if user
      if user.update(user_name: params[:user_name])
        render json: { id: user.id, user_id: user.user_id, user_name: user.user_name }, status: :ok
      else
        render json: { error: "更新に失敗しました", details: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      # ユーザーが存在しない場合は404エラーを返す
      render json: { error: "User not found" }, status: :not_found
    end

  end

# ユーザー情報の取得
  def show
    # ユーザーIDを取得
    user_id = params[:id]
    # ユーザーを検索
    user = User.find_by(id: user_id)
    user_battledata = BattleDetail.find_by(player_id: user_id)

    if user
      # ユーザーが存在する場合はJSON形式で返す
      render json: 
      {
        id: user.id,
        user_name: user.user_name,
        
      }
    else
      # ユーザーが存在しない場合は404エラーを返す
      render json: { error: "User not found" }, status: :not_found
    end
  end
end
