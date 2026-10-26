require "test_helper"

class BugReportsControllerTest < ActionDispatch::IntegrationTest
  test "notes a bug with its page, marks it fixed, and lists open bugs first" do
    post "/api/v1/bug_reports", params: { bug: { note: "Map flickers", page: "/game/ABC" } }, as: :json
    first = response.parsed_body
    post "/api/v1/bug_reports", params: { bug: { note: "Typo on Lists tab" } }, as: :json

    patch "/api/v1/bug_reports/#{first['id']}", params: { bug: { fixed: true } }, as: :json
    assert response.parsed_body["fixed"]

    get "/api/v1/bug_reports"
    assert_equal ["Typo on Lists tab", "Map flickers"], response.parsed_body.map { _1["note"] }
    assert_equal "/game/ABC", response.parsed_body.last["page"]

    patch "/api/v1/bug_reports/#{first['id']}", params: { bug: { fixed: false } }, as: :json
    refute response.parsed_body["fixed"]
  end

  test "a bug needs a note" do
    post "/api/v1/bug_reports", params: { bug: { note: " " } }, as: :json
    assert_response 422
  end

  test "deletes a bug" do
    bug = BugReport.create!(note: "Gone")
    delete "/api/v1/bug_reports/#{bug.id}"
    refute BugReport.exists?(bug.id)
  end
end
