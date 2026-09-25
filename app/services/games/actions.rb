# Everything a player can do to a game. Each action takes the game's row lock
# and first plays any villain turns that came due, so phones acting at the
# same moment see one consistent order of events.
module Games
  class Actions
    class Invalid < StandardError; end

    def self.create!(park:, preset:, host_name:, rules: {})
      villain = Villains.for_park(park) or raise Invalid, "#{park} doesn't have a villain yet"
      Game.transaction do
        game = Game.create!(park:, preset:, villain_key: villain.key, rules: rules.slice("villain_on_fail", "days", "day_start", "day_end"))
        game.board.areas.each { game.area_states.create!(area: _1) }
        host = game.players.create!(name: host_name, host: true)
        game.log!("joined", "#{host.name} created the game.", player: host)
        [game, host]
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Invalid, e.record.errors.full_messages.to_sentence
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
        @player.update!(hand: game.draw_challenges(game.hand_size)) if game.active?
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
        game.players.each { _1.update!(hand: game.draw_challenges(game.hand_size)) }
        game.log!("started", "The game has begun! #{game.villain.display_name} acts every #{game.settings['tick_minutes']} minutes.", at: now)
        game.save!
      end
    end

    def move!(area)
      locked(playing: true) do
        raise Invalid, "#{area} is not in #{game.park}" unless game.board.areas.include?(area)

        me.update!(current_area: area)
        game.log!("moved", "#{me.name} is in #{area}.", player: me, area:)
      end
    end

    def complete!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge, state = playable(challenge_id)
        check_rules!(challenge, state)

        before = snapshot(state)
        claimed_from = state.owner
        if state.players? && state.influence.zero?
          state.update!(locked: true)
          kind = "locked"
          message = "#{me.name} locked #{state.area} with \"#{challenge.title}\"."
        else
          influence = [state.influence - challenge.difficulty, 0].max
          state.update!(influence:, owner: influence.zero? ? "players" : state.owner)
          kind = "claimed"
          message =
            if !state.players? then "#{me.name} weakened #{game.villain.display_name} in #{state.area} with \"#{challenge.title}\" (#{influence} influence left)."
            elsif claimed_from == "players" then "#{me.name} cleared #{game.villain.display_name}'s influence from #{state.area}."
            elsif claimed_from == "villain" then "#{me.name} took #{state.area} back from #{game.villain.display_name}!"
            else "#{me.name} claimed #{state.area} with \"#{challenge.title}\"!"
            end
        end

        me.coins += challenge.difficulty
        drawn = replace_card(challenge)
        next_tick_at = game.next_tick_at
        event = game.log!(kind, message, at: now, player: me, area: state.area, undo: {
          "challenge_id" => challenge.id, "drawn" => drawn, "coins" => challenge.difficulty,
          "area" => state.area, "before" => before, "after" => snapshot(state),
        })
        VillainEngine.new(game).check_player_win!(now)
        if game.finished?
          event.data["undo"].merge!("won" => true, "next_tick_at" => next_tick_at)
          event.save!
        end
        game.save!
      end
    end

    def fail!(challenge_id, now = Time.current)
      locked(now, playing: true) do
        challenge, = playable(challenge_id)
        drawn = replace_card(challenge)
        undo = game.rules["villain_on_fail"] ? nil : { "challenge_id" => challenge.id, "drawn" => drawn, "coins" => 0 }
        game.log!("failed", "#{me.name} failed \"#{challenge.title}\".", at: now, player: me, undo:)
        VillainEngine.new(game).handle(:challenge_failed, at: now)
        game.save!
      end
    end

    # Reverses the player's most recent completed or failed challenge, as long
    # as nothing has touched that area since.
    def undo!(now = Time.current)
      locked(now) do
        event = game.game_events.where(player_id: me.id, kind: %w[claimed locked failed]).last
        undo = event&.data&.dig("undo")
        raise Invalid, "Nothing to undo" if undo.nil? || event.data["undone"]

        if undo["won"]
          raise Invalid, "The game is over" if now >= game.ends_at

          game.status = "active"
          game.result = nil
          game.next_tick_at = Time.zone.parse(undo["next_tick_at"].to_s)
          game.game_events.where(kind: "finished").where("id > ?", event.id).destroy_all
        elsif !game.active?
          raise Invalid, "The game isn't running"
        end

        if undo["area"]
          state = game.area(undo["area"])
          unless snapshot(state) == undo["after"]
            raise Invalid, "#{state.area} has changed since then, so this can't be undone"
          end

          state.update!(undo["before"])
        end

        me.coins -= undo["coins"]
        me.hand = me.hand - undo["drawn"] + [undo["challenge_id"]]
        me.save!
        game.challenge_discard = game.challenge_discard - [undo["challenge_id"]]
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
      raise Invalid, "Tell us which area you're in first" if me.current_area.blank?

      [Challenge.find(challenge_id), game.area(me.current_area)]
    end

    def check_rules!(challenge, state)
      area = state.area
      villain = game.villain
      if challenge.area && challenge.area != area
        raise Invalid, "\"#{challenge.title}\" has to be done in #{challenge.area}"
      end
      if challenge.difficulty < villain.min_difficulty(area)
        raise Invalid, "#{villain.display_name} requires a difficulty #{villain.min_difficulty(area)}+ challenge in #{area}"
      end
      if state.villain? && game.board.neighbors(area).none? { game.area(_1).players? }
        raise Invalid, "To attack #{area} you need to hold an area next to it"
      end
      if state.players? && state.locked?
        raise Invalid, "#{area} is already locked"
      end
      if state.players? && state.influence.zero? && challenge.difficulty < 2
        raise Invalid, "Locking #{area} takes a difficulty 2+ challenge"
      end
    end

    # Swaps a played card for a new one and returns the new card's ids.
    def replace_card(challenge)
      game.discard_challenge(challenge.id)
      me.hand = me.hand - [challenge.id]
      drawn = game.draw_challenges(1)
      me.hand = me.hand + drawn
      me.save!
      drawn
    end

    def snapshot(state)
      { "owner" => state.owner, "influence" => state.influence, "locked" => state.locked }
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
