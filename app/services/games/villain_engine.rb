# The villain's side of the game, modeled on Pandemic's infection deck.
#
# Every area has an owner and a strength. The villain deck holds two cards
# per area plus "Villain Rising" cards spread evenly through it. Each villain
# turn draws `rate` cards:
#   * area card  -> the villain pushes 1 into that area: it weakens a players
#                   area (at 0 the area is unclaimed), claims an unclaimed one
#                   at strength 1, and strengthens one of her own. Drawing her
#                   own area at strength 3+ makes it spill over: it grows by
#                   1 and pushes into every neighbor too (internally an
#                   "outbreak"; players never see that word or a count of
#                   them). Thresholds come from the game's settings.
#   * rising     -> escalation +1: the villain plays one more card per turn,
#                   starting with the turn it's drawn on. It doesn't count as
#                   one of the turn's cards.
#
# Everything the villain does starts from `handle(trigger)`, so new triggers
# (e.g. a failed challenge, in hard mode) can be switched on per preset.
module Games
  class VillainEngine
    RISING = "rising".freeze

    # Cards the villain plays per turn: one, plus one per Villain Rising.
    def self.rate_for(escalation)
      1 + escalation
    end

    def self.build_deck(board, risings, rng)
      areas = (board.areas.map { "area:#{_1}" } * 2).shuffle(random: rng)
      return areas if risings.zero?

      piles = areas.each_slice((areas.size / risings.to_f).ceil).to_a
      piles.flat_map { |pile| (pile + [RISING]).shuffle(random: rng) }
    end

    # The rules every villain plays by, with this game's numbers, as shown
    # under the villain's own rules on the players' phones.
    def self.general_rules(game)
      s = game.settings
      risings = s["risings"]
      [
        "The villain takes a turn every #{s['tick_minutes']} minutes#{', and if you fail a challenge' if game.hard_mode?}.",
        "Each turn the villain plays area cards from a deck with two cards for every area.",
        "An area card puts 1 influence point into that area.",
        "If a villain's area is already at #{s['outbreak_at']} or more, it spills over. That area and every adjacent area get one influence.",
        ("The deck also hides #{risings} Villain Rising #{'card'.pluralize(risings)}. Each one makes the villain play one more card per turn." if risings.positive?),
        "You lose if the villain claims the whole park, or if time runs out while the villain holds more areas than you.",
      ].compact
    end

    attr_reader :game

    def initialize(game)
      @game = game
    end

    def villain = game.villain

    def handle(trigger, at:)
      case trigger
      when :timer then villain_turn(at)
      when :challenge_failed then villain_turn(at) if game.hard_mode?
      else raise ArgumentError, "Unknown villain trigger #{trigger}"
      end
    end

    # Everything logged during a turn is tagged with its number, which is
    # what the villain turn pop-up on the players' phones shows.
    def villain_turn(at)
      game.tick_count += 1
      game.villain_turn_number = game.tick_count
      cards = self.class.rate_for(game.escalation)
      board = game.area_states.to_h { [_1.area, [_1.owner, _1.strength]] }
      game.set_power("forecast", nil) # the top of the deck is about to change
      if game.power("stalls", 0).positive?
        game.set_power("stalls", game.power("stalls", 0) - 1)
        game.log!("villain_turn", "#{villain.display_name} skips this turn.", at:, board:)
        game.log!("stalled", "Stall! #{villain.display_name} skips this turn.", at:, action: "Stall", actor: "players",
                                                                              note: "#{villain.display_name} skips this turn")
        return
      end

      game.log!("villain_turn", "#{villain.display_name} plays #{cards} #{'card'.pluralize(cards)}.", at:, board:)
      # A Villain Rising isn't one of the turn's cards, and the extra card it
      # adds is played this turn.
      played = 0
      while game.active? && played < self.class.rate_for(game.escalation)
        card = draw_card(at)
        break if card.nil?

        played += 1 unless card == RISING
      end
      villain.on_tick(at) if game.active?
      game.set_power("shields", []) # shields last one real turn
    ensure
      game.villain_turn_number = nil
    end

    # The villain pushes `amount` into an area.
    def push(name, amount, at, from_outbreak: false)
      state = game.area(name)
      who = villain.display_name

      if state.villain?
        if state.strength >= game.outbreak_at && !from_outbreak
          outbreak(name, at, grow: amount)
        else
          state.update!(strength: state.strength + amount)
          game.log!("strength", "#{who}'s hold on #{name} grows (strength #{state.strength}).", at:, **area_after(state))
        end
        return
      end

      if state.players? && game.shielded?(name)
        game.log!("shielded", "The shield protects #{name}.", at:, **area_after(state))
        return
      end

      if state.players?
        hit = [amount, state.strength].min
        state.strength -= hit
        amount -= hit
        if state.strength.positive?
          state.save!
          game.log!("weakened", "#{who} weakens your hold on #{name} (strength #{state.strength}).", at:, **area_after(state))
          return
        end
        state.update!(owner: "neutral", strength: 0)
        game.log!("lost_area", "#{who} knocked you out of #{name.chomp('.')}.", at:, **area_after(state))
        amount = [amount, 1].max if villain.usurps?
      end
      return if amount.zero?

      state.update!(owner: "villain", strength: amount)
      game.log!("takeover", "#{who} has taken #{name}!", at:, **area_after(state))
      villain.on_takeover(state, at)
      check_loss!(at)
    end

    # Ends a game whose clock ran out and awards a medal.
    def finish_on_time!(at)
      states = game.area_states
      ours = states.count(&:players?)
      theirs = states.count(&:villain?)
      share = ours.to_f / states.size

      # The park starts split evenly, so holding your ground is a bronze.
      result =
        if ours < theirs then "lost"
        elsif share >= 0.75 then "gold"
        elsif ours > theirs then "silver"
        else "bronze"
        end
      finish!(result, "Time's up! You hold #{ours} of #{states.size} areas; #{villain.display_name} holds #{theirs}.", at)
    end

    # Players win early by holding every area.
    def check_player_win!(at)
      return unless game.area_states.all?(&:players?)

      finish!("gold", "You hold the whole park. #{villain.display_name} is defeated!", at)
    end

    private

    # An area as it stands after a change, for the turn replay on the phones.
    def area_after(state)
      { area: state.area, owner: state.owner, strength: state.strength }
    end

    def draw_card(at)
      reshuffle_discard(at) if game.villain_draw.empty?
      card, *rest = game.villain_draw
      game.villain_draw = rest
      return if card.nil?

      play_card(card, at)
      card
    end

    def play_card(card, at)
      name = card == RISING ? "Villain Rising" : card.delete_prefix("area:")
      game.log!("villain_card", "#{villain.display_name} plays #{name}.", at:, card: name, **(card == RISING ? {} : { area: name }))
      if card == RISING
        escalate(at)
      else
        game.villain_discard = game.villain_discard + [card]
        name = card.delete_prefix("area:")
        push(name, villain.card_push(game.area(name)), at)
      end
    end

    public

    # A villain power takes one of the players' areas outright, keeping its
    # strength.
    def seize(name, at)
      state = game.area(name)
      state.update!(owner: "villain")
      game.log!("takeover", "#{villain.display_name} has taken #{name}!", at:, **area_after(state))
      villain.on_takeover(state, at)
      check_loss!(at)
    end

    # Deals the discard pile back into an empty deck (also used by Forecast).
    def reshuffle_discard(at)
      game.villain_draw = game.villain_discard.shuffle(random: game.rng)
      game.villain_discard = []
      game.log!("villain", "#{villain.display_name} regroups and reshuffles the villain deck.", at:)
    end

    private

    def escalate(at)
      game.escalation += 1
      rate = self.class.rate_for(game.escalation)
      game.log!("rising", "Villain Rising! #{villain.display_name} now plays #{rate} #{'card'.pluralize(rate)} a turn.", at:)
      villain.on_escalation(at)
    end

    # The area grows by what the card pushed (usually 1) and pushes into
    # every neighbor.
    def outbreak(name, at, grow: 1)
      game.outbreaks += 1
      game.log!("outbreak", "#{villain.display_name}'s hold on #{name} spills over into its neighbors!", at:, area: name)
      state = game.area(name)
      state.update!(strength: state.strength + grow)
      game.log!("strength", "#{villain.display_name}'s hold on #{name} grows (strength #{state.strength}).", at:, **area_after(state))
      game.board.neighbors(name).each do |neighbor|
        break unless game.active?

        push(neighbor, villain.outbreak_spread, at, from_outbreak: true)
      end
      check_loss!(at)
    end

    # Besides running out of time behind, the only way to lose.
    def check_loss!(at)
      return unless game.active? && game.area_states.all?(&:villain?)

      finish!("lost", "#{villain.display_name} has taken the whole park.", at)
    end

    def finish!(result, message, at)
      game.status = "finished"
      game.result = result
      game.next_tick_at = nil
      game.log!("finished", message, at:, result:)
    end
  end
end
