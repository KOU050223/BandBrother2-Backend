class Api::MusicController < ActionController::API
  def index

  end

  def show
    music_id = params[:id]
    json_path = Rails.root.join('public', 'music1.json')
    if File.exist?(json_path)
      json_data = File.read(json_path)
      render json: JSON.parse(json_data)
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end
end
