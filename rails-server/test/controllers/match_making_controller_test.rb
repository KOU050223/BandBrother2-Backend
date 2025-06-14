require "test_helper"

class MatchMakingControllerTest < ActionDispatch::IntegrationTest
  test "should get join" do
    get match_making_join_url
    assert_response :success
  end

  test "should get destroy" do
    get match_making_destroy_url
    assert_response :success
  end
end
