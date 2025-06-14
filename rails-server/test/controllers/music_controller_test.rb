require "test_helper"

class MusicControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get music_index_url
    assert_response :success
  end

  test "should get show" do
    get music_show_url
    assert_response :success
  end
end
