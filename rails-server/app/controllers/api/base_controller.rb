class Api::BaseController < ActionController::API
  # Add CORS headers for API responses
  before_action :set_cors_headers
  
  private
  
  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = request.headers['Origin'] || '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token, Auth-Token, Email, X-User-Token, X-User-Email'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end
end
