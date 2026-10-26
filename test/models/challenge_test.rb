require "test_helper"

# Challenges live in the database and are edited in the app; the files in
# config/game add new ones (see GameContent).
class ChallengeTest < ActiveSupport::TestCase
  setup do
    GameContent.forget!
    ContentSeed.create!(key: GameContent::BASELINE)
  end

  # Runs the block with a challenges folder (and an empty claims folder)
  # holding the given files.
  def with_files(files)
    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, "claims"))
      Dir.mkdir(File.join(dir, "challenges"))
      write(dir, files)
      yield dir
    end
  end

  def write(dir, files)
    files.each do |name, yaml|
      path = File.join(dir, "challenges", name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, yaml)
    end
    @writes = @writes.to_i + 1
    later = (Time.current + @writes.minutes).to_time
    Dir.glob(File.join(dir, "**/*")).each { File.utime(later, later, _1) }
  end

  def seed(dir)
    GameContent.seed!(challenges_dir: File.join(dir, "challenges"), claims_dir: File.join(dir, "claims"))
  end

  test "the first load makes the challenges match the files, as before the editor" do
    ContentSeed.delete_all
    Challenge.create!(title: "Wave", reward: 7)
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}
") { seed(_1) }
    assert_equal [["Wave", 1]], Challenge.pluck(:title, :reward)

    Challenge.create!(title: "Made in the app", reward: 2)
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}
") { seed(_1) }
    assert Challenge.exists?(title: "Made in the app"), "only the first load does that"
  end

  test "the real files load cleanly" do
    assert_nil GameContent.seed!
    assert Challenge.where(park: nil).exists?
    assert Challenge.where(park: "Animal Kingdom").exists?
    assert ClaimChallenge.where(park: "Magic Kingdom").exists?
    assert ChallengeList.exists?(name: "philharmagic_effects")
    refute ChallengeList.exists?(name: "geoguessr"), "photo lists stay as files"
  end

  test "each file is a park" do
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}\n", "animal_kingdom.yml" => "- {title: Yeti, reward: 2}\n") { seed(_1) }
    assert_nil Challenge.find_by!(title: "Wave").park
    assert_equal "Animal Kingdom", Challenge.find_by!(title: "Yeti").park
  end

  test "new challenges in the files are added, and challenges made in the app are kept" do
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}\n") do |dir|
      seed(dir)
      Challenge.create!(title: "Made in the app", reward: 4)

      write(dir, "anywhere.yml" => "- {title: Wave, reward: 1}\n- {title: From the repo, reward: 2}\n")
      assert_nil seed(dir)
      assert Challenge.exists?(title: "Made in the app")
      assert Challenge.exists?(title: "From the repo")
      assert Challenge.exists?(title: "Wave")
    end
  end

  test "edits and deletes made in the app aren't undone by the files" do
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}\n- {title: Dance, reward: 1}\n") do |dir|
      seed(dir)
      Challenge.find_by!(title: "Wave").update!(title: "Big wave", reward: 5)
      Challenge.find_by!(title: "Dance").destroy!

      write(dir, "anywhere.yml" => "- {title: Wave, reward: 2}\n- {title: Dance, reward: 1}\n")
      seed(dir)
      assert_equal [5, nil, nil], [Challenge.find_by!(title: "Big wave").reward, Challenge.find_by(title: "Wave"), Challenge.find_by(title: "Dance")]
    end
  end

  test "a file title that's already in the database is left alone" do
    Challenge.create!(title: "Wave", reward: 7)
    with_files("anywhere.yml" => "- {title: Wave, reward: 1}\n") { seed(_1) }
    assert_equal 7, Challenge.find_by!(title: "Wave").reward
  end

  test "mistakes are reported by file and title, and the good ones still load" do
    problem = with_files("animal_kingdom.yml" => "- {title: Hard, reward: 11}\n- {title: Fine, reward: 2}\n") { seed(_1) }
    assert_match "animal_kingdom.yml: Hard: Reward must be a whole number from 1 to 10", problem
    assert Challenge.exists?(title: "Fine")
    refute Challenge.exists?(title: "Hard")
  end

  test "file names must be anywhere or one of the tracker's parks" do
    problem = with_files("narnia.yml" => "- {title: Wardrobe, reward: 1}\n") { seed(_1) }
    assert_match "narnia.yml: there's no park called that", problem
  end

  test "Universal Orlando is one park covering both Universal parks" do
    with_files("universal_orlando.yml" => "- {title: Gringotts, reward: 2}\n") { seed(_1) }
    assert_equal "Universal Orlando", Challenge.find_by!(title: "Gringotts").park
  end

  test "parks without a board can have challenges, but they aren't dealt" do
    with_files("epcot.yml" => "- {title: Soarin, reward: 2}\n") { seed(_1) }
    assert_equal "Epcot", Challenge.find_by!(title: "Soarin").park
    assert_empty Challenge.for_park("Magic Kingdom").where(title: "Soarin")
  end

  test "unknown fields and YAML typos are reported" do
    assert_match "unknown field category", with_files("anywhere.yml" => "- {title: A, reward: 1, category: find}\n") { seed(_1) }
    problem = with_files("anywhere.yml" => "- title: Big 5\n  description: Spot these: Lion, Rhino\n  reward: 3\n") { seed(_1) }
    assert_match "anywhere.yml: line 2", problem
    assert_match "anywhere.yml: challenge 2 is empty", with_files("anywhere.yml" => "- {title: Good, reward: 1}\n-\n") { seed(_1) }
  end

  test "list items added in the files join the list, and items removed in the app stay removed" do
    with_files("lists/smells.yml" => "- Pie\n- Smoke\n") do |dir|
      seed(dir)
      list = ChallengeList.find_by!(name: "smells")
      list.update!(items: ["Pie", "Roses"])

      write(dir, "lists/smells.yml" => "- Pie\n- Smoke\n- Rain\n")
      seed(dir)
      assert_equal %w[Pie Roses Rain], list.reload.items
    end
  end

  test "a list in the database is what cards deal from" do
    ChallengeList.create!(name: "smells", items: %w[Pie Smoke])
    challenge = Challenge.create!(title: "Sniff", reward: 1, list_from: "smells", list_count: 2)
    assert_equal %w[Pie Smoke], challenge.list_items
  end

  test "claim cards added in the files are added per area" do
    with_files({}) do |dir|
      File.write(File.join(dir, "claims", "magic_kingdom.yml"), "Adventureland:\n  - {title: Touch the tiki, description: Any tiki}\n")
      seed(dir)
      assert_equal ["Touch the tiki"], ClaimChallenge.cards("Magic Kingdom", "Adventureland").map(&:title)

      problem = (File.write(File.join(dir, "claims", "magic_kingdom.yml"), "Narnia:\n  - {title: Wardrobe}\n") && GameContent.forget! && nil) || seed(dir)
      assert_match "isn't an area of Magic Kingdom", problem
    end
  end

  test "export gives everything back as YAML" do
    Challenge.create!(title: "Wave", reward: 1)
    data = YAML.safe_load(GameContent.export)
    assert_includes data["challenges"]["anywhere"].map { _1["title"] }, "Wave"
  end
end
