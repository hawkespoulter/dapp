# Loads the park game's content from config/game into the database: hand
# challenges (challenges/*.yml), list items (challenges/lists/*.yml) and
# claim cards (claims/*.yml). Content can be added both ways: each entry in
# the files loads once (remembered in content_seeds), so new entries in the
# repo show up in the app, while anything edited, renamed or deleted in the
# app stays that way. An entry whose title is already in the database is
# left alone. Returns the problems found (nil when there are none); an entry
# with a problem is retried until it loads.
module GameContent
  CLAIMS_DIR = Rails.root.join("config/game/claims")

  # Off in tests, which build their content from fixtures.
  mattr_accessor :auto_seed, default: !Rails.env.test?

  # Loads what's new, if a file changed since this process last looked.
  def self.ensure!
    seed! if auto_seed
  end

  def self.seed!(challenges_dir: Challenge::DIR, claims_dir: CLAIMS_DIR)
    challenges_dir = Pathname(challenges_dir)
    claims_dir = Pathname(claims_dir)
    stamp = [challenges_dir, claims_dir].flat_map { Dir.glob(_1.join("**/*.yml").to_s) }.sort.map { [_1, File.mtime(_1)] }
    @loaded ||= {}
    key = [challenges_dir.to_s, claims_dir.to_s]
    return @loaded[key][:problems] if @loaded.dig(key, :stamp) == stamp

    seeded = ContentSeed.pluck(:key).to_set
    problems = []
    baseline!(challenges_dir, seeded) unless seeded.include?(BASELINE)
    seed_lists(challenges_dir.join("lists"), seeded)
    problems.concat(seed_challenges(challenges_dir, seeded))
    problems.concat(seed_claims(claims_dir, seeded))
    problems = problems.presence&.join("
")
    @loaded[key] = { stamp:, problems: }
    problems
  end

  BASELINE = "baseline".freeze

  # Before the editor, the files were the whole truth: the first time this
  # runs, the challenges are made to match them exactly (updating changed
  # ones, removing ones the files dropped). From then on the app owns them.
  def self.baseline!(dir, seeded)
    entries = Challenge.parse(dir)
    Challenge.transaction do
      Challenge.where.not(title: entries.map { _1["title"] }).destroy_all
      entries.each do |attrs|
        fresh = Challenge.from_file_entry(attrs)
        challenge = Challenge.find_or_initialize_by(title: attrs["title"])
        challenge.assign_attributes(fresh.attributes.slice(*%w[description reward park list_from list_count]))
        mark("challenge:#{attrs['title']}", seeded) if challenge.save
      end
    end
    mark(BASELINE, seeded)
  rescue Challenge::InvalidFile
    # fix the files first; seed_challenges reports what's wrong
  end

  def self.forget!
    @loaded = nil
  end

  def self.mark(key, seeded)
    ContentSeed.create!(key:)
  rescue ActiveRecord::RecordNotUnique
    # another process got there first
  ensure
    seeded << key
  end

  # Text lists only: a list of photos stays a file. New items in a file are
  # added to the end of the list in the database.
  def self.seed_lists(dir, seeded)
    Dir.glob(dir.join("*.yml").to_s).sort.each do |path|
      name = File.basename(path, ".yml")
      items = Challenge.read_list(path)
      next if items.any?(Hash)

      fresh = items.map(&:to_s).reject { seeded.include?("list:#{name}:#{_1}") }
      next if fresh.empty?

      list = ChallengeList.find_or_initialize_by(name:)
      list.items = list.items.to_a | fresh
      list.save!
      fresh.each { mark("list:#{name}:#{_1}", seeded) }
    end
  end

  def self.seed_challenges(dir, seeded)
    Challenge.files(dir).flat_map do |path|
      Challenge.parse_file(path).filter_map do |attrs|
        key = "challenge:#{attrs['title']}"
        next if seeded.include?(key)

        unless Challenge.exists?(title: attrs["title"])
          challenge = Challenge.from_file_entry(attrs)
          next "#{attrs['file']}: #{attrs['title']}: #{challenge.errors.full_messages.to_sentence}" unless challenge.save
        end
        mark(key, seeded)
        nil
      end
    rescue Challenge::InvalidFile => e
      [e.message]
    end
  end

  def self.seed_claims(dir, seeded)
    parks = Park.names.index_by { Challenge.file_name_for(_1) }
    Dir.glob(dir.join("*.yml").to_s).sort.flat_map do |path|
      file = File.basename(path)
      park = parks[File.basename(path, ".yml")]
      next ["claims/#{file}: there's no park called that"] unless park

      data = YAML.safe_load(File.read(path)) || {}
      next ["claims/#{file}: should map each area to a list of challenges"] unless data.is_a?(Hash)

      data.flat_map do |area, list|
        Array(list).each_with_index.filter_map do |entry, i|
          next "claims/#{file}: #{area}: each challenge needs a title" unless entry.is_a?(Hash) && entry["title"].present?

          title = entry["title"].to_s.strip
          key = "claim:#{park}:#{area}:#{title}"
          next if seeded.include?(key)

          unless ClaimChallenge.exists?(park:, area:, title:)
            card = ClaimChallenge.new(park:, area:, title:, description: entry["description"].to_s.strip,
                                      position: i)
            next "claims/#{file}: #{area}: #{card.errors.full_messages.to_sentence}" unless card.save
          end
          mark(key, seeded)
          nil
        end
      end
    rescue Psych::SyntaxError => e
      ["claims/#{file}: line #{e.line} can't be read (#{e.problem})"]
    end
  end

  # Everything, back as YAML (for safekeeping or to copy into the files).
  def self.export
    challenges = Challenge.order(:park, :title).group_by { _1.park || Challenge::ANYWHERE }.transform_values do |list|
      list.map do |c|
        { "title" => c.title, "description" => c.description.presence, "reward" => c.reward,
          "list" => (c.list_from && { "from" => c.list_from, "count" => c.list_count }) }.compact
      end
    end
    claims = ClaimChallenge.ordered.group_by(&:park).transform_values do |cards|
      cards.group_by(&:area).transform_values { |list| list.map { { "title" => _1.title, "description" => _1.description.presence }.compact } }
    end
    lists = ChallengeList.order(:name).to_h { [_1.name, _1.items] }
    { "challenges" => challenges, "claims" => claims, "lists" => lists }.to_yaml
  end
end
