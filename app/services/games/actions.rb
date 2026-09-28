# Everything a player can do to a game. Each action takes the game's row lock
# and first plays any villain turns that came due, so phones acting at the
# same moment see one consistent order of events.
#
# Challenges pay coins into a team pool. Coins buy influence into a team
# stash, and each influence placed on an area moves it one point toward the
# players: it weakens a villain area (at 0 it's unclaimed), claims an
# unclaimed area at strength 1, or strengthens one of ours, with no cap.
module Games
  class Actions
    class Invalid < StandardError; end

    UNDOABLE = %w[completed failed bought placed claimed].freeze
    # Bought with team coins; prices are the price_<key> game settings.
    POWERS = %w[forecast stall shield redraw double_down safety_net].freeze
    POWER_NAMES = {
      "forecast" => "Forecast", "stall" => "Stall", "shield" => "Shield",
      "redraw" => "Redraw", "double_down" => "Double Down", "safety_net" => "Safety Net"
    }.freeze

    def self.create!(park:, preset:, host_name:, rules: {})
      villain = Villains.for_park(park) or raise Invalid, "#{park} doesn't have a villain yet"
      Game.transaction do
        preset_settings = GamePreset.for(preset).settings.merge(rules.slice("days", "day_start", "day_end"))
        game = Game.create!(park:, preset:, villain_key: villain.key,
                            rules: { "settings" => preset_settings })
        game.board.areas.each { game.area_states.create!(area: _1) }
        host = game.players.create!(name: host_name, host: true)
        game.log!("joined", "#{host.name} created the game.", player: host)
        [game, host]
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Invalid, e.record.errors.full_messages.to_sentence
    rescue ArgumentError => e
      raise Invalid, e.message
    end

    attr_reader :game, :player

    def initialize(game, player = nil)
      @game = game
      @player = player
    end

    def join!(name)
      locked do
        raise Invalid, "This game is over" if game.finished?

        @player = game.players.create!(name:)
        if game.active?
          @player.deal(game.draw_challenges(game.hand_size), game.rng)
          @player.save!
        end
        game.log!("joined", "#{name} joined the game.", player: @player)
        @player
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Invalid, e.record.errors.full_messages.to_sentence
    end

    def start!(now = Time.current)
      locked do
        raise Invalid, "Only the host can start the game" unless me.host?
        raise Invalid, "The game has already started" unless game.lobby?

        game.rules = game.rules.merge("windows" => windows_from(now))
        game.status = "active"
        game.started_at = now
        game.ends_at = game.clock.ends_at
        game.next_tick_at = game.clock.advance(now, game.tick_seconds)
        game.villain_draw = VillainEngine.build_deck(game.board, game.settings["risings"], game.rng)
        game.villain.setup!(now)
        game.players.each do |player|
          player.deal(game.draw_challenges(game.hand_size), game.rng)
          player.save!
        end
        game.log!("started", "The game has begun! #{game.villain.display_name} acts every #{game.settings['tick_minutes']} minutes.", at: now)
        game.save!
      end
    end

    # For testing: the villain takes a turn right now. Her timer is unchanged.
    def force_villain_turn!(now = Time.current)
      locked(now, playing: true) do
        VillainEngine.new(game).villain_turn(now)
        game.save!
      end
    end

    # Challenges can be done anywhere. They pay coins into the team pool.
    def complete!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge = playable(challenge_id)
        coins = challenge.reward
        doubled = take_charge("double_down")
        coins *= 2 if doubled
        game.coins += coins
        me.coins += coins
        hand_before = [me.hand, me.card_lists]
        replace_card(challenge)
        note = doubled ? ", doubled by Double Down" : ""
        record("completed", "#{me.name} completed \"#{challenge.title}\" (+#{coins} coins#{note}).", now,
               "coins" => coins, "earned" => coins, "hand" => hand_before, "discard" => challenge.id,
               "double_down" => doubled || nil)
      end
    end

    def fail!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge = playable(challenge_id)
        hand_before = [me.hand, me.card_lists]
        replace_card(challenge)
        failed("#{me.name} failed \"#{challenge.title}\".", now, "hand" => hand_before, "discard" => challenge.id)
      end
    end

    # Completing an area's claim challenge there takes the area at strength 1,
    # whether it was unclaimed or the villain's.
    def complete_claim!(area, now = Time.current)
      locked(now, playing: true) do
        state = claimable(area)
        card = game.claim_card(area)
        before = snapshot(state)
        state.update!(owner: "players", strength: 1)
        game.claim_attempted!(area)
        record("claimed", "#{me.name} completed \"#{card.title}\" and claimed #{area}!", now,
               "areas" => { area => [before, snapshot(state)] })
      end
    end

    # A failed claim challenge counts as a failed challenge.
    def fail_claim!(area, now = Time.current)
      locked(now, playing: true) do
        claimable(area)
        card = game.claim_card(area)
        game.claim_attempted!(area)
        failed("#{me.name} failed \"#{card.title}\" in #{area}.", now, {})
      end
    end

    # Turns team coins into influence in the team stash.
    def buy_influence!(count, now = Time.current)
      locked(now, playing: true) do
        count = count.to_i
        cost = count * game.influence_price
        raise Invalid, "Buy at least 1 influence" if count < 1
        raise Invalid, "That costs #{cost} coins and the team has #{game.coins}" if cost > game.coins

        game.coins -= cost
        game.influence_stash += count
        record("bought", "#{me.name} bought #{count} influence for #{cost} coins.", now,
               "coins" => -cost, "stash" => count)
      end
    end

    # Spends influence from the stash on an area.
    def place_influence!(area, count, now = Time.current)
      locked(now, playing: true) do
        count = count.to_i
        raise Invalid, "#{area} is not in #{game.park}" unless game.board.areas.include?(area)
        raise Invalid, "Place at least 1 influence" if count < 1
        raise Invalid, "The team only has #{game.influence_stash} influence" if count > game.influence_stash

        state = game.area(area)
        if state.villain? && game.board.neighbors(area).none? { game.area(_1).players? }
          raise Invalid, "To attack #{area} you need to hold an area next to it"
        end

        raise Invalid, "Claim #{area} by completing its claim challenge there" if state.neutral?

        step_cost = game.villain.placement_cost(area)
        if count < step_cost
          raise Invalid, "#{game.villain.display_name} makes each point in #{area} cost #{step_cost} influence"
        end

        before = snapshot(state)
        points = count / step_cost
        points = [points, state.strength].min if state.villain? # it stops at unclaimed
        spent = points * step_cost
        points.times { push_toward_players(state) }
        state.save!
        game.influence_stash -= spent

        record("placed", placement_message(state, before, spent), now,
               "stash" => -spent, "areas" => { area => [before, snapshot(state)] })
      end
    end

    # Reverses the player's most recent challenge, purchase or placement, as
    # long as nothing has changed the areas it touched and the team hasn't
    # already spent what it gained.
    def undo!(now = Time.current)
      locked(now) do
        event = game.game_events.where(player_id: me.id, kind: UNDOABLE + ["power"]).last
        raise Invalid, "Power-ups can't be undone" if event&.kind == "power"

        undo = event&.data&.dig("undo")
        raise Invalid, "Nothing to undo" if undo.nil? || event.data["undone"]

        if undo["won"]
          raise Invalid, "The game is over" if now >= game.ends_at
        elsif !game.active?
          raise Invalid, "The game isn't running"
        end

        areas = undo.fetch("areas", {})
        areas.each do |name, (_before, after)|
          raise Invalid, "#{name} has changed since then, so this can't be undone" unless snapshot(game.area(name)) == after
        end
        raise Invalid, "The team has already spent those coins" if game.coins < undo.fetch("coins", 0)
        raise Invalid, "The team has already placed that influence" if game.influence_stash < undo.fetch("stash", 0)

        if undo["won"]
          game.status = "active"
          game.result = nil
          game.next_tick_at = Time.zone.parse(undo["next_tick_at"].to_s)
          game.game_events.where(kind: "finished").where("id > ?", event.id).destroy_all
        end
        areas.each { |name, (before, _after)| game.area(name).update!(before) }
        game.coins -= undo.fetch("coins", 0)
        game.influence_stash -= undo.fetch("stash", 0)
        me.coins -= undo.fetch("earned", 0)
        # The hand comes back exactly as it was, list items included. (Older
        # games stored [hand before, hand after] without list items.)
        if undo["hand"]
          hand, lists = undo["hand"]
          me.hand = hand
          me.card_lists = lists if lists.is_a?(Hash)
        end
        me.save!
        game.challenge_discard = game.challenge_discard - [undo["discard"]] if undo["discard"]
        %w[double_down safety_net].each { give_charge(_1) if undo[_1] }
        event.update!(data: event.data.merge("undone" => true))
        game.log!("undo", "#{me.name} undid: #{event.message}", at: now, player: me)
        game.save!
      end
    end

    # Changes this game's balance while it's running (or in the lobby). The
    # villain's timer change applies from the turn after the one already
    # scheduled; a new game length moves the end; hands grow or shrink to a
    # new hand size.
    def update_balance!(changes, now = Time.current)
      locked(now) do
        raise Invalid, "The game is over" if game.finished?

        before = game.settings
        edited = GamePreset.coerce(changes, before.keys & GamePreset::LIVE_FIELDS)
        after = before.merge(edited)
        problems = GamePreset.problems(after)
        raise Invalid, problems.to_sentence if problems.any?

        changed = edited.reject { |field, value| before[field] == value }
        raise Invalid, "Nothing changed" if changed.empty?

        game.rules = game.rules.merge("settings" => after)
        if changed.key?("hours") && game.active?
          ends_at = game.started_at + after["hours"].hours
          raise Invalid, "That would end the game before now" if ends_at <= now

          game.rules = game.rules.merge("windows" => [[game.started_at, ends_at]])
          game.ends_at = ends_at
        end
        resize_hands if changed.key?("hand_size") && game.active?

        summary = changed.map do |field, value|
          label = GamePreset::FIELDS.dig(field, :label) || field
          "#{label} #{show_setting(before[field])} → #{show_setting(value)}"
        end
        game.log!("settings", "#{me.name} changed this game's balance: #{summary.join('; ')}.", at: now, player: me)
        game.save!
      end
    end

    # Spends team coins on a power-up. Shield needs one of your areas.
    def use_power!(power, area: nil, now: Time.current)
      locked(now, playing: true) do
        raise Invalid, "Unknown power-up #{power}" unless POWERS.include?(power)

        price = game.settings["price_#{power}"].to_i
        raise Invalid, "#{POWER_NAMES[power]} costs #{price} coins and the team has #{game.coins}" if price > game.coins

        message = send("power_#{power}", area, now)
        game.coins -= price
        me.save!
        game.log!("power", "#{me.name} used #{POWER_NAMES[power]}: #{message}", at: now, player: me,
                                                                            power:, coins: price)
        game.save!
      end
    end

    # Throws away one of the three cards a Forecast revealed.
    def forecast_discard!(index, now = Time.current)
      locked(now, playing: true) do
        forecast = game.power("forecast", nil)
        raise Invalid, "You don't have a forecast to use" unless forecast && forecast["player"] == me.id
        raise Invalid, "The villain's deck has changed since your forecast" unless game.villain_draw.first(forecast["cards"].size) == forecast["cards"]

        index = index.to_i
        raise Invalid, "Pick one of the forecast cards" unless index.between?(0, forecast["cards"].size - 1)

        draw = game.villain_draw.dup
        card = draw.delete_at(index)
        game.villain_draw = draw
        game.villain_discard = game.villain_discard + [card]
        game.set_power("forecast", nil)
        game.log!("forecast", "#{me.name} threw away #{card_name(card)} from the villain's deck.", at: now, player: me)
        game.save!
      end
    end

    private

    def power_forecast(_area, now)
      raise Invalid, "Throw away a card from your last forecast first" if game.power("forecast", nil)

      engine = VillainEngine.new(game)
      engine.reshuffle_discard(now) if game.villain_draw.empty?
      cards = game.villain_draw.first(3)
      raise Invalid, "The villain's deck is empty" if cards.empty?

      game.set_power("forecast", { "player" => me.id, "cards" => cards })
      "the next cards are #{cards.map { card_name(_1) }.to_sentence}."
    end

    def power_stall(_area, _now)
      game.set_power("stalls", game.power("stalls", 0) + 1)
      "#{game.villain.display_name} will skip the next turn."
    end

    def power_shield(area, _now)
      raise Invalid, "Pick one of your areas to shield" unless area && game.board.areas.include?(area) && game.area(area).players?
      raise Invalid, "#{area} is already shielded" if game.shielded?(area)

      game.set_power("shields", game.power("shields", []) + [area])
      "#{area} is safe during #{game.villain.display_name}'s next turn."
    end

    def power_redraw(_area, _now)
      old = me.hand
      raise Invalid, "You have no cards to redraw" if old.empty?

      fresh = game.draw_challenges(old.size)
      old.each { game.discard_challenge(_1) }
      me.deal(fresh, game.rng)
      "a whole new hand."
    end

    def power_double_down(_area, _now)
      give_charge("double_down")
      "the next challenge they complete pays double."
    end

    def power_safety_net(_area, _now)
      raise Invalid, "Safety Net only matters in hard mode" unless game.hard_mode?

      give_charge("safety_net")
      "the next challenge they fail won't wake #{game.villain.display_name}."
    end

    # Double Down and Safety Net charges belong to the player who bought them.
    def give_charge(key)
      game.set_power(key, game.power(key, []) + [me.id])
    end

    def take_charge(key)
      charges = game.power(key, [])
      return false unless (i = charges.index(me.id))

      game.set_power(key, charges.dup.tap { _1.delete_at(i) })
      true
    end

    # Logs a failed challenge (a hand card or a claim challenge). In hard mode
    # the villain takes a turn unless the player's Safety Net catches it.
    def failed(message, now, undo)
      if game.hard_mode? && take_charge("safety_net")
        record("failed", "#{message} The Safety Net kept #{game.villain.display_name} still.", now,
               undo.merge("safety_net" => true))
      elsif game.hard_mode?
        me.save!
        game.log!("failed", message, at: now, player: me)
        VillainEngine.new(game).handle(:challenge_failed, at: now)
        game.save!
      else
        record("failed", message, now, undo)
      end
    end

    # An area the team can go and claim.
    def claimable(area)
      raise Invalid, "#{area} is not in #{game.park}" unless game.board.areas.include?(area)

      state = game.area(area)
      raise Invalid, "#{area} is already yours" if state.players?
      unless game.villain.enterable?(state)
        raise Invalid, "You can't enter #{area} while #{game.villain.display_name} holds it"
      end

      state
    end

    # Deals extra cards to short hands and discards the last cards of long ones.
    def resize_hands
      game.players.each do |player|
        hand = player.hand
        if hand.size > game.hand_size
          hand.drop(game.hand_size).each { game.discard_challenge(_1) }
          player.deal(hand.first(game.hand_size), game.rng)
        elsif hand.size < game.hand_size
          player.deal(hand + game.draw_challenges(game.hand_size - hand.size), game.rng)
        end
        player.save!
      end
    end

    def show_setting(value)
      value == true ? "on" : value == false ? "off" : value.to_s
    end

    def card_name(card)
      card == VillainEngine::RISING ? "a Villain Rising" : card.delete_prefix("area:")
    end

    # The acting player, taken from the locked game so hand changes are seen
    # by draw_challenges.
    def me
      @me ||= game.players.find { _1.id == player&.id } || raise(Invalid, "You are not in this game")
    end

    def locked(now = Time.current, playing: false)
      game.with_lock do
        @me = nil
        game.advance!(now)
        raise Invalid, "The game isn't running" if playing && !game.active?

        yield
      end
    end

    def playable(challenge_id)
      challenge_id = challenge_id.to_i
      raise Invalid, "That challenge isn't in your hand" unless me.hand.include?(challenge_id)

      Challenge.find(challenge_id)
    end

    # Moves an area one point toward the players.
    # Moves an area one point toward the players: a villain area weakens (at 0
    # it's unclaimed) and one of theirs grows. Claiming takes a claim challenge.
    def push_toward_players(state)
      if state.villain?
        state.strength -= 1
        state.owner = "neutral" if state.strength.zero?
      else
        state.strength += 1
      end
    end

    def placement_message(state, before, spent)
      villain = game.villain.display_name
      from = before["owner"]
      result =
        if state.players? then "(strength #{state.strength})"
        elsif state.neutral? then "and drove #{villain} out"
        else "(#{villain}'s strength #{state.strength})"
        end
      "#{me.name} placed #{spent} influence in #{state.area} #{result}"
    end

    # Logs an undoable action and ends the game if the players just won.
    def record(kind, message, now, undo)
      next_tick_at = game.next_tick_at
      event = game.log!(kind, message, at: now, player: me, undo:)
      VillainEngine.new(game).check_player_win!(now)
      if game.finished?
        event.data["undo"].merge!("won" => true, "next_tick_at" => next_tick_at)
        event.save!
      end
      me.save!
      game.save!
    end

    # Swaps a played card for a new one in the same spot in the hand, so the
    # other cards don't move.
    def replace_card(challenge)
      game.discard_challenge(challenge.id)
      fresh = game.draw_challenges(1).first
      me.deal(me.hand.flat_map { _1 == challenge.id ? [fresh].compact : [_1] }, game.rng)
    end

    def snapshot(state)
      { "owner" => state.owner, "strength" => state.strength }
    end

    def windows_from(now)
      settings = game.settings
      return [[now, now + settings["hours"].hours]] unless settings["days"]

      start_h, start_m = settings["day_start"].split(":").map(&:to_i)
      end_h, end_m = settings["day_end"].split(":").map(&:to_i)
      date = now.to_date
      date += 1 if now >= date.in_time_zone.change(hour: end_h, min: end_m)
      Array.new(settings["days"].to_i) do |i|
        day = (date + i).in_time_zone
        open = day.change(hour: start_h, min: start_m)
        [i.zero? ? [open, now].max : open, day.change(hour: end_h, min: end_m)]
      end
    end
  end
end
