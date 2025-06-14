class Api::MusicController < ApplicationController
  def index

    # ダミーの音楽データを作成（配列とハッシュの形式）
    musics = [
      { id: 1, title: "テスト曲1", artist: "テストアーティストA" },
      { id: 2, title: "テスト曲2", artist: "テストアーティストB" },
      { id: 3, title: "テスト曲3", artist: "テストアーティストC" }
    ]

    # この配列をJSON形式でクライアントに返す
    render json: musics
  end

  def show
    music_id = params[:id]
    render json: { id: music_id }
  end
end
