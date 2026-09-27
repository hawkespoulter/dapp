# Park game API. Players identify themselves with the X-Player-Token header
# they receive when creating or joining a game.
class Api::V1::GamesController < ApplicationController
  before_action :set_game, except: %i[ create parks ]

  rescue_from Games::Actions::Invalid do |e|
    render json: { error: e.message }, status: 422
  end

  # GET /game_parks
  def parks
    render json: {
      parks: Game.playable_parks.map { |park| { park:, villain: Villains.for_park(park) } },
      presets: GamePreset.seeded.map { _1.settings.merge("key" => _1.key) },
    }
  end

  # POST /games
  def create
    game, player = Games::Actions.create!(
      park: params.require(:park),
      preset: params.require(:preset),
      host_name: params.require(:name),
      rules: params.fetch(:rules, {}).permit(:days, :day_start, :day_end).to_h,
    )
    render json: { token: player.auth_token, state: game.state_for(player) }, status: :created
  end

  # GET /games/:code
  def show
    @game.with_lock { @game.advance! }
    render json: @game.state_for(current_player)
  end

  # POST /games/:code/join
  def join
    player = actions.join!(params.require(:name))
    render json: { token: player.auth_token, state: @game.state_for(player) }, status: :created
  end

  # POST /games/:code/start
  def start
    actions.start!
    render_state
  end

  # POST /games/:code/complete
  def complete
    actions.complete!(params.require(:challenge_id))
    render_state
  end

  # POST /games/:code/fail
  def fail_challenge
    actions.fail!(params.require(:challenge_id))
    render_state
  end

  # POST /games/:code/buy
  def buy
    actions.buy_influence!(params.require(:count))
    render_state
  end

  # POST /games/:code/place
  def place
    actions.place_influence!(params.require(:area), params.require(:count))
    render_state
  end

  # POST /games/:code/villain_turn (testing: make the villain move now)
  def villain_turn
    actions.force_villain_turn!
    render_state
  end

  # POST /games/:code/undo
  def undo
    actions.undo!
    render_state
  end

  private

  def set_game
    @game = Game.find_by!(join_code: params[:code].to_s.upcase)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "No game with code #{params[:code]}" }, status: :not_found
  end

  def current_player
    token = request.headers["X-Player-Token"]
    @current_player ||= token.present? ? @game.players.find_by(auth_token: token) : nil
  end

  def actions
    Games::Actions.new(@game, current_player)
  end

  def render_state
    render json: @game.state_for(current_player&.reload)
  end
end
