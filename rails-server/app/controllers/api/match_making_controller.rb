class Api::MatchMakingController < ApplicationController
  before_action :authenticate_user!, except: [:join, :destroy, :status]
  
  def join
    user_id = params[:user_id]
    difficulty = params[:difficulty] || 'Easy'
    
    if user_id.blank?
      render json: { success: false, error: 'user_id is required' }, status: 400
      return
    end
    
    # 待機中のルームを探す
    waiting_room = Room.where(status: 'waiting', player2_id: nil).first
    
    if waiting_room
      # 既存のルームに参加
      waiting_room.update!(
        player2_id: user_id,
        player2_difficulty: difficulty,
        status: 'ready'
      )
      
      render json: {
        success: true,
        room_id: waiting_room.id,
        role: 'player2',
        message: 'マッチングしました'
      }
    else
      # 新しいルームを作成
      new_room = Room.create!(
        player1_id: user_id,
        player1_difficulty: difficulty,
        status: 'waiting'
      )
      
      render json: {
        success: true,
        room_id: new_room.id,
        role: 'player1',
        message: '対戦相手を待っています'
      }
    end
  rescue => e
    Rails.logger.error "MatchMaking join error: #{e.message}"
    render json: { success: false, error: e.message }, status: 500
  end

  def destroy
    user_id = params[:user_id]
    
    if user_id.blank?
      render json: { success: false, error: 'user_id is required' }, status: 400
      return
    end
    
    # ユーザーが参加しているルームを探して削除
    room = Room.where(
      "(player1_id = ? OR player2_id = ?) AND status IN (?)",
      user_id, user_id, ['waiting', 'ready']
    ).first
    
    if room
      room.destroy
      render json: { success: true, message: 'マッチングをキャンセルしました' }
    else
      render json: { success: false, message: 'キャンセルするルームが見つかりません' }
    end
  rescue => e
    Rails.logger.error "MatchMaking destroy error: #{e.message}"
    render json: { success: false, error: e.message }, status: 500
  end

  def status
    room_id = params[:room_id]
    
    if room_id.blank?
      render json: { error: 'room_id is required' }, status: 400
      return
    end
    
    room = Room.find(room_id)
    
    render json: {
      room_id: room.id,
      status: room.status,
      player1_id: room.player1_id,
      player2_id: room.player2_id,
      player1_difficulty: room.player1_difficulty,
      player2_difficulty: room.player2_difficulty,
      player_count: [room.player1_id, room.player2_id].compact.size
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'ルームが見つかりません' }, status: 404
  rescue => e
    Rails.logger.error "MatchMaking status error: #{e.message}"
    render json: { error: e.message }, status: 500
  end

  private

  def authenticate_user!
    # Firebase認証の実装があればここに追加
    # 現在は開発用にスキップ
  end
end
