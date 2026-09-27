# The Game settings page: tune each preset's balance and see the win/loss
# record. Finished games (with the settings they were played under) have
# their own paged list.
class Api::V1::GameSettingsController < ApplicationController
  FINISHED_PER_PAGE = 10

  before_action :set_preset, only: %i[ update reset ]

  # GET /game_settings
  def index
    finished = Game.where(status: "finished")
    problem = Challenge.refresh
    render json: {
      challenges: { counts: Challenge.group(:park).count.transform_keys { _1 || Challenge::ANYWHERE }, problem: },
      presets: GamePreset.seeded,
      record: finished.group(:preset, :result).count.each_with_object({}) { |((preset, result), n), all| (all[preset] ||= {})[result] = n },
      finished_count: finished.count,
    }
  end

  # GET /finished_games?page=1 (newest first)
  def finished
    finished = Game.where(status: "finished")
    total = finished.count
    pages = [(total / FINISHED_PER_PAGE.to_f).ceil, 1].max
    page = params.fetch(:page, 1).to_i.clamp(1, pages)
    games = finished.includes(:players).order(updated_at: :desc, id: :desc)
                    .offset((page - 1) * FINISHED_PER_PAGE).limit(FINISHED_PER_PAGE)
    render json: { games: games.map { finished_game(_1) }, page:, pages:, total: }
  end

  # PATCH /game_settings/:key
  def update
    @preset.update_settings!(params.require(:settings).permit!)
    render json: @preset
  rescue ActiveRecord::RecordInvalid
    render json: { error: @preset.errors.full_messages.to_sentence }, status: 422
  end

  # POST /game_settings/:key/reset
  def reset
    @preset.reset!
    render json: @preset
  end

  private

  def set_preset
    @preset = GamePreset.seeded.find_by!(key: params[:key])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unknown game length #{params[:key]}" }, status: :not_found
  end

  def finished_game(game)
    summary = game.game_events.where(kind: "finished").last
    {
      code: game.join_code,
      park: game.park,
      preset: game.preset,
      preset_label: game.settings["label"],
      result: game.result,
      summary: summary&.message,
      started_at: game.started_at,
      finished_at: summary&.occurred_at,
      players: game.players.map(&:name),
      settings: game.settings,
    }
  end
end
