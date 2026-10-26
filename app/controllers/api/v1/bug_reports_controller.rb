# The running bug list behind the navbar's bug button.
class Api::V1::BugReportsController < ApplicationController
  # GET /bug_reports
  def index
    render json: BugReport.listed
  end

  # POST /bug_reports
  def create
    save(BugReport.new(params.require(:bug).permit(:note, :page)))
  end

  # PATCH /bug_reports/:id (note, or fixed: true/false)
  def update
    bug = BugReport.find(params[:id])
    attrs = params.require(:bug).permit(:note, :fixed)
    bug.note = attrs[:note] if attrs.key?(:note)
    bug.fixed_at = ActiveModel::Type::Boolean.new.cast(attrs[:fixed]) ? (bug.fixed_at || Time.current) : nil if attrs.key?(:fixed)
    save(bug)
  end

  # DELETE /bug_reports/:id
  def destroy
    BugReport.find(params[:id]).destroy!
    head :no_content
  end

  private

  def save(bug)
    if bug.save
      render json: bug
    else
      render json: { error: bug.errors.full_messages.to_sentence }, status: 422
    end
  end
end
