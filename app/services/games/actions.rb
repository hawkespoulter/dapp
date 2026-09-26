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

    UNDOABLE = %w[completed failed bought placed].freeze

    def self.create!(park:, preset:, host_name:, rules: {})
      villain = Villains.for_park(park) or raise Invalid, "#{park} doesn't have a villain yet"
      Game.transaction do
        preset_settings = GamePreset.for(preset).settings.merge(rules.slice("days", "day_start", "day_end"))
        game = Game.create!(park:, preset:, villain_key: villain.key,
                            rules: rules.slice("villain_on_fail").merge("settings" => preset_settings))
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

    # Challenges can be done anywhere. They pay coins into the team pool.
    def complete!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge = playable(challenge_id)
        coins = challenge.reward
        game.coins += coins
        me.coins += coins
        hand_before = [me.hand, me.card_lists]
        replace_card(challenge)
        record("completed", "#{me.name} completed \"#{challenge.title}\" (+#{coins} coins).", now,
               "coins" => coins, "earned" => coins, "hand" => hand_before, "discard" => challenge.id)
      end
    end

    def fail!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge = playable(challenge_id)
        hand_before = [me.hand, me.card_lists]
        replace_card(challenge)
        message = "#{me.name} failed \"#{challenge.title}\"."
        if game.rules["villain_on_fail"]
          me.save!
          game.log!("failed", message, at: now, player: me)
          VillainEngine.new(game).handle(:challenge_failed, at: now)
          game.save!
        else
          record("failed", message, now, "hand" => hand_before, "discard" => challenge.id)
        end
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

        step_cost = game.villain.placement_cost(area)
        if count < step_cost
          raise Invalid, "#{game.villain.display_name} makes each point in #{area} cost #{step_cost} influence"
        end

        before = snapshot(state)
        points = count / step_cost
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
        event = game.game_events.where(player_id: me.id, kind: UNDOABLE).last
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
        event.update!(data: event.data.merge("undone" => true))
        game.log!("undo", "#{me.name} undid: #{event.message}", at: now, player: me)
        game.save!
      end
    end

    private

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
    def push_toward_players(state)
      if state.villain?
        state.strength -= 1
        state.owner = "neutral" if state.strength.zero?
      elsif state.neutral?
        state.assign_attributes(owner: "players", strength: 1)
      else
        state.strength += 1
      end
    end

    def placement_message(state, before, spent)
      villain = game.villain.display_name
      from = before["owner"]
      result =
        if state.players? && from != "players" then "and claimed it (strength #{state.strength})!"
        elsif state.players? then "(strength #{state.strength})"
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

    # Swaps a played card for a new one.
    def replace_card(challenge)
      game.discard_challenge(challenge.id)
      me.deal(me.hand - [challenge.id] + game.draw_challenges(1), game.rng)
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
