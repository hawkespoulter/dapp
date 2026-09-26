# The villain's side of the game, modeled on Pandemic's infection deck.
#
# Every area has an owner and a strength. The villain deck holds two cards
# per area plus "Villain Rising" cards spread evenly through it. Each villain
# turn draws `rate` cards:
#   * area card  -> the villain pushes 1 into that area: it weakens a players
#                   area (at 0 the area is unclaimed), claims an unclaimed one
#                   at strength 1, and strengthens one of her own. Drawing her
#                   own area at strength 3+ is an outbreak instead, which
#                   pushes into every neighbor. Thresholds come from the game's settings.
#   * rising     -> escalation +1 (more cards per turn), the bottom area card
#                   takes a push of 3, and the discard pile goes back on top.
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

    # The villain pushes `amount` into an area.
    def push(name, amount, at, from_outbreak: false)
      state = game.area(name)
      who = villain.display_name

      if state.villain?
        if state.strength >= game.outbreak_at && !from_outbreak
          outbreak(name, at)
        else
          state.update!(strength: state.strength + amount)
          game.log!("strength", "#{who}'s hold on #{name} grows (strength #{state.strength}).", at:, area: name)
        end
        return
      end

      if state.players?
        hit = [amount, state.strength].min
        state.strength -= hit
        amount -= hit
        if state.strength.positive?
          state.save!
          game.log!("weakened", "#{who} weakens your hold on #{name} (strength #{state.strength}).", at:, area: name)
          return
        end
        state.update!(owner: "neutral", strength: 0)
        game.log!("lost_area", "#{who} knocked you out of #{name}.", at:, area: name)
      end
      return if amount.zero?

      state.update!(owner: "villain", strength: amount)
      game.log!("takeover", "#{who} has taken #{name}!", at:, area: name)
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

    def draw_card(at)
      reshuffle_discard(at) if game.villain_draw.empty?
      card, *rest = game.villain_draw
      game.villain_draw = rest
      return if card.nil?

      if card == RISING
        escalate(at)
      else
        game.villain_discard = game.villain_discard + [card]
        push(card.delete_prefix("area:"), 1, at)
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
      push(card.delete_prefix("area:"), game.settings["rising_push"], at, from_outbreak: true)

      game.villain_draw = game.villain_discard.shuffle(random: game.rng) + game.villain_draw
      game.villain_discard = []
      villain.on_escalation(at)
    end

    def outbreak(name, at)
      game.outbreaks += 1
      game.log!("outbreak", "Outbreak in #{name}! (#{game.outbreaks}/#{game.outbreak_limit})", at:, area: name)
      game.board.neighbors(name).each do |neighbor|
        break unless game.active?

        push(neighbor, villain.outbreak_spread, at, from_outbreak: true)
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
