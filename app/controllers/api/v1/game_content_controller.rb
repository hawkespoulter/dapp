# The challenge editor: hand challenges, claim cards and item lists, all
# stored in the database (the files under config/game only seed it).
class Api::V1::GameContentController < ApplicationController
  # GET /game_content?park=Magic Kingdom (or anywhere)
  def index
    GameContent.ensure!
    park = params[:park].presence
    park = nil if park == Challenge::ANYWHERE
    areas = park && ParkBoard.config.key?(park) ? ParkBoard.for(park).areas : []
    render json: {
      parks: [Challenge::ANYWHERE, *Park.names],
      park: park || Challenge::ANYWHERE,
      challenges: Challenge.where(park:).order(:title).map(&:as_editor_json),
      areas:,
      claims: park ? ClaimChallenge.where(park:).ordered : [],
      lists: ChallengeList.order(:name),
      photo_lists: Dir.glob(Challenge::LISTS_DIR.join("*/").to_s).map { File.basename(_1) }.sort,
    }
  end

  # GET /game_content/export
  def export
    GameContent.ensure!
    send_data GameContent.export, filename: "park-game-content.yml", type: "text/yaml"
  end

  # POST /challenges, PATCH /challenges/:id, DELETE /challenges/:id
  def create_challenge
    save(Challenge.new(challenge_params))
  end

  def update_challenge
    challenge = Challenge.find(params[:id])
    challenge.assign_attributes(challenge_params)
    save(challenge)
  end

  def destroy_challenge
    Challenge.find(params[:id]).destroy!
    head :no_content
  end

  # POST /claim_challenges, PATCH /claim_challenges/:id, DELETE ...
  def create_claim
    save(ClaimChallenge.new(params.require(:claim).permit(:park, :area, :title, :description)))
  end

  def update_claim
    card = ClaimChallenge.find(params[:id])
    card.assign_attributes(params.require(:claim).permit(:title, :description))
    save(card)
  end

  def destroy_claim
    ClaimChallenge.find(params[:id]).destroy!
    head :no_content
  end

  # POST /challenge_lists, PATCH /challenge_lists/:id, DELETE ...
  def create_list
    save(ChallengeList.new(list_params))
  end

  def update_list
    list = ChallengeList.find(params[:id])
    if list_params.key?(:name) && list_params[:name] != list.name && list.used_by.any?
      return render json: { error: "Rename it after taking it off: #{list.used_by.to_sentence}" }, status: 422
    end

    list.assign_attributes(list_params)
    save(list)
  end

  def destroy_list
    list = ChallengeList.find(params[:id])
    return render json: { error: "It's used by #{list.used_by.to_sentence}" }, status: 422 if list.used_by.any?

    list.destroy!
    head :no_content
  end

  private

  def challenge_params
    attrs = params.require(:challenge).permit(:title, :description, :reward, :park, :list_from, :list_count)
    # Only what was sent changes (the in-game editor sends just the text).
    attrs[:park] = nil if attrs.key?(:park) && (attrs[:park].blank? || attrs[:park] == Challenge::ANYWHERE)
    if attrs.key?(:list_from)
      attrs[:list_from] = attrs[:list_from].presence
      attrs[:list_count] = attrs[:list_from] ? Integer(attrs[:list_count].to_s, exception: false) : nil
    end
    attrs[:reward] = Integer(attrs[:reward].to_s, exception: false) || attrs[:reward] if attrs.key?(:reward)
    attrs
  end

  def list_params
    attrs = params.require(:list).permit(:name, items: [])
    attrs[:name] = attrs[:name].to_s.strip if attrs.key?(:name)
    attrs
  end

  def save(record)
    if record.save
      render json: record.respond_to?(:as_editor_json) ? record.as_editor_json : record
    else
      render json: { error: record.errors.full_messages.to_sentence }, status: 422
    end
  end
end
