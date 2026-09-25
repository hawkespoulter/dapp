# The villain's side of the game, modeled on Pandemic's infection deck.
#
# The game starts with the park split between the players and the villain.
# Influence on a villain area is its strength.
#
# The villain deck holds two cards per area plus "Villain Rising" cards spread
# evenly through it. Each villain turn draws `rate` cards:
#   * area card  -> +1 influence there. At 3 influence the villain takes the area.
#                   A villain area gains strength instead; one already at full
#                   strength has an outbreak that spreads influence to every
#                   neighbor.
#   * rising     -> escalation +1 (more cards per turn), the bottom area card
#                   gets 3 influence, and the discard pile goes back on top.
#
# Everything the villain does starts from `handle(trigger)`, so new triggers
# (e.g. a failed challenge) can be switched on per game through `rules`.
module Games
  class VillainEngine
    RATE_TRACK = [1, 1, 2, 2, 3].freeze
    RISING = "rising".freeze

    def self.rate_for(escalation)
      RATE_TRACK[[escalation, RATE_TRACK.size - 1].min]
    end

    def self.build_deck(board, risings, rng)
      areas = (board.areas.map { "area:#{_1}" } * 2).shuffle(random: rng)
      piles = areas.each_slice((areas.size / risings.to_f).ceil).to_a
      piles.flat_map { |pile| (pile + [RISING]).shuffle(random: rng) }
    end

    attr_reader :game

    def initialize(game)
      @game = game
    end

    def villain = game.villain

    def handle(trigger, at:)
      case trigger
      when :timer then villain_turn(at)
      when :challenge_failed then villain_turn(at) if game.rules["villain_on_fail"]
      else raise ArgumentError, "Unknown villain trigger #{trigger}"
      end
    end

    def villain_turn(at)
      game.tick_count += 1
      self.class.rate_for(game.escalation).times do
        break unless game.active?

        draw_card(at)
      end
      villain.on_tick(at) if game.active?
    end

    def add_influence(name, amount, at, from_outbreak: false)
      state = game.area(name)
      if state.villain? && state.influence >= AreaState::MAX_INFLUENCE
        outbreak(name, at) unless from_outbreak
      elsif state.villain?
        state.update!(influence: [state.influence + amount, AreaState::MAX_INFLUENCE].min)
        game.log!("influence", "#{villain.display_name}'s hold on #{name} grows (#{state.influence}/#{AreaState::MAX_INFLUENCE}).", at:, area: name)
      elsif state.players? && state.locked?
        game.log!("blocked", "#{name} is locked and holds off #{villain.display_name}.", at:, area: name)
      else
        state.update!(influence: [state.influence + amount, AreaState::MAX_INFLUENCE].min)
        game.log!("influence", "#{villain.display_name}'s influence grows in #{name} (#{state.influence}/#{AreaState::MAX_INFLUENCE}).", at:, area: name)
        takeover(state, at) if state.influence >= AreaState::MAX_INFLUENCE
      end
    end

    # Ends a game whose clock ran out and awards a medal.
    def finish_on_time!(at)
      states = game.area_states
      ours = states.count(&:players?)
      theirs = states.count(&:villain?)
      share = ours.to_f / states.size

      result =
        if ours <= theirs then "lost"
        elsif share >= 0.75 then "gold"
        elsif share >= 0.5 then "silver"
        else "bronze"
        end
      finish!(result, "Time's up! You hold #{ours} of #{states.size} areas; #{villain.display_name} holds #{theirs}.", at)
    end

    # Players win early by owning and locking every area.
    def check_player_win!(at)
      return unless game.area_states.all? { _1.players? && _1.locked? }

      finish!("gold", "Every area is claimed and locked. #{villain.display_name} is defeated!", at)
    end

    private

    def draw_card(at)
      reshuffle_discard(at) if game.villain_draw.empty?
      card, *rest = game.villain_draw
      game.villain_draw = rest
      return if card.nil?

      if card == RISING
        escalate(at)
      else
        game.villain_discard = game.villain_discard + [card]
        add_influence(card.delete_prefix("area:"), 1, at)
      end
    end

    def reshuffle_discard(at)
      game.villain_draw = game.villain_discard.shuffle(random: game.rng)
      game.villain_discard = []
      game.log!("villain", "#{villain.display_name} regroups and reshuffles the villain deck.", at:)
    end

    def escalate(at)
      game.escalation += 1
      game.log!("rising", "Villain Rising! #{villain.display_name} now plays #{self.class.rate_for(game.escalation)} cards a turn.", at:)

      draw = game.villain_draw.dup
      index = draw.rindex { _1.start_with?("area:") }
      card = index ? draw.delete_at(index) : "area:#{game.board.areas.sample(random: game.rng)}"
      game.villain_draw = draw
      game.villain_discard = game.villain_discard + [card]
      add_influence(card.delete_prefix("area:"), AreaState::MAX_INFLUENCE, at)

      game.villain_draw = game.villain_discard.shuffle(random: game.rng) + game.villain_draw
      game.villain_discard = []
      villain.on_escalation(at)
    end

    def takeover(state, at)
      state.update!(owner: "villain", locked: false, influence: AreaState::MAX_INFLUENCE)
      game.log!("takeover", "#{villain.display_name} has taken #{state.area}!", at:, area: state.area)
      villain.on_takeover(state, at)
      check_loss!(at)
    end

    def outbreak(name, at)
      game.outbreaks += 1
      game.log!("outbreak", "Outbreak in #{name}! (#{game.outbreaks}/#{game.outbreak_limit})", at:, area: name)
      game.board.neighbors(name).each do |neighbor|
        break unless game.active?

        add_influence(neighbor, villain.outbreak_spread, at, from_outbreak: true)
      end
      check_loss!(at)
    end

    def check_loss!(at)
      return unless game.active?

      if game.outbreaks >= game.outbreak_limit
        finish!("lost", "Too many outbreaks. #{villain.display_name} has overrun the park.", at)
      elsif game.area_states.all?(&:villain?)
        finish!("lost", "#{villain.display_name} has taken the whole park.", at)
      end
    end

    def finish!(result, message, at)
      game.status = "finished"
      game.result = result
      game.next_tick_at = nil
      game.log!("finished", message, at:, result:)
    end
  end
end
