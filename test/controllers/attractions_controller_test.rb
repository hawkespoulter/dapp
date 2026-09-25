require "test_helper"

class AttractionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attraction = attractions(:one)
  end

  test "should get index" do
    get api_v1_attractions_url, as: :json
    assert_response :success
  end

  test "should create attraction" do
    assert_difference("Attraction.count") do
      post api_v1_attractions_url, params: { attraction: { completed: @attraction.completed, area: @attraction.area, name: @attraction.name, park: @attraction.park } }, as: :json
    end

    assert_response :created
  end

  test "should show attraction" do
    get api_v1_attraction_url(@attraction), as: :json
    assert_response :success
  end

  test "should update attraction" do
    patch api_v1_attraction_url(@attraction), params: { attraction: { completed: @attraction.completed, area: @attraction.area, name: @attraction.name, park: @attraction.park } }, as: :json
    assert_response :success
  end

  test "should destroy attraction" do
    assert_difference("Attraction.count", -1) do
      delete api_v1_attraction_url(@attraction), as: :json
    end

    assert_response :no_content
  end
end
