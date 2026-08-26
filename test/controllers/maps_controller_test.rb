require "test_helper"

class MapsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "map-user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Map User",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
  end

  teardown do
    Warden.test_reset!
  end

  test "guest is redirected to sign in" do
    get map_path
    assert_redirected_to new_user_session_path
  end

  test "signed in user can view map" do
    login_as @user, scope: :user

    get map_path
    assert_response :success
    assert_match "graph-map", response.body
    assert_match "data-controller=\"graph-map\"", response.body
  end
end
