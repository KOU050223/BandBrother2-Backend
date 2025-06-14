class MusicController < ApplicationController
  def index
    # JSON形式でクライアントにレスポンスを返します
    render json: musics
  end

  def show
    music_id = params[:id]
    render json: { id: @music.id }
  end
end
