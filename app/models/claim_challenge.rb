# The claim challenges: to take an area you don't hold, the team goes there
# and completes that area's claim challenge. They live in
# config/game/claims/<park>.yml as a map of area name to a list of
# challenges (title + description), and are re-read when a file changes.
class ClaimChallenge
  DIR = Rails.root.join("config/game/claims")

  Card = Data.define(:area, :title, :description) do
    def as_json(*) = { title:, description: }
  end

  class << self
    # The area's claim cards, or a stand-in when the file has none for it.
    def cards(park, area)
      found = decks(park)[area]
      found.presence || [Card.new(area:, title: "Stake your claim", description: "Go to #{area} together and take a group photo there.")]
    end

    # How many cards each playable park's file holds, and what's wrong with
    # any of them (nil when all is well).
    def summary
      parks = Game.playable_parks
      problems = parks.filter_map { |park| problem(park) }
      { counts: parks.index_with { |park| decks(park).values.sum(&:size) }, problem: problems.join("\n").presence }
    end

    def path(park, dir = DIR)
      Pathname(dir).join("#{Challenge.file_name_for(park)}.yml")
    end

    private

    def decks(park)
      load_file(park)[:decks]
    end

    def problem(park)
      load_file(park)[:problem]
    end

    # Cached per file until it changes on disk.
    def load_file(park)
      file = path(park)
      stamp = file.exist? ? file.mtime : nil
      @cache ||= {}
      cached = @cache[park]
      return cached if cached && cached[:stamp] == stamp

      @cache[park] = { stamp:, **parse(park, file) }
    end

    def parse(park, file)
      return { decks: {}, problem: nil } unless file.exist?

      data = YAML.safe_load(File.read(file)) || {}
      raise ArgumentError, "should map each area to a list of challenges" unless data.is_a?(Hash)

      areas = ParkBoard.config.key?(park) ? ParkBoard.for(park).areas : []
      unknown = data.keys - areas
      raise ArgumentError, "#{unknown.to_sentence} #{unknown.one? ? 'isn\'t an area' : 'aren\'t areas'} of #{park}" if unknown.any?

      decks = data.to_h do |area, list|
        cards = Array(list).map do |entry|
          raise ArgumentError, "#{area}: each challenge needs a title" unless entry.is_a?(Hash) && entry["title"].present?

          Card.new(area:, title: entry["title"].to_s.strip, description: entry["description"].to_s.strip)
        end
        [area, cards]
      end
      { decks:, problem: nil }
    rescue Psych::SyntaxError => e
      { decks: {}, problem: "#{file.basename}: line #{e.line} can't be read (#{e.problem})" }
    rescue ArgumentError => e
      { decks: {}, problem: "#{file.basename}: #{e.message}" }
    end
  end
end
