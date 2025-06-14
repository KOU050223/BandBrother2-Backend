require "test_helper"

class MatchNotificationControllerTest < ActionDispatch::IntegrationTest
  test "should get notify_match" do
    get match_notification_notify_match_url
    assert_response :success
  end
end
