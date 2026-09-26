require "test_helper"

class ChallengeTest < ActiveSupport::TestCase
  # Runs the block with a challenges folder holding the given files.
  def with_files(files)
    Dir.mktmpdir do |dir|
      write(dir, files)
      yield dir
    end
  end

  def write(dir, files)
    files.each { |name, yaml| File.write(File.join(dir, name), yaml) }
    later = (Time.current + 1.minute).to_time
    [dir, *Dir.glob(File.join(dir, "*"))].each { File.utime(later, later, _1) }
  end

  test "the real challenge files load cleanly" do
    Challenge.sync!
    assert Challenge.where(park: nil).exists?
    assert Challenge.where(park: "Animal Kingdom").exists?
  end

  test "each file is a park, and together they are the whole deck" do
    with_files(
      "anywhere.yml" => "- {title: Wave, difficulty: 1}\n",
      "animal_kingdom.yml" => "- {title: Yeti, area: Asia, difficulty: 2}\n",
    ) { Challenge.sync!(_1) }
    assert_equal %w[Wave Yeti], Challenge.order(:title).pluck(:title)
    assert_equal [nil, nil], Challenge.find_by(title: "Wave").then { [_1.park, _1.area] }
    assert_equal ["Animal Kingdom", "Asia"], Challenge.find_by(title: "Yeti").then { [_1.park, _1.area] }

    with_files("anywhere.yml" => "- {title: Yeti, difficulty: 3}\n") { Challenge.sync!(_1) }
    yeti = Challenge.find_by!(title: "Yeti")
    assert_equal [nil, nil, 3], [yeti.park, yeti.area, yeti.difficulty]
    assert_equal 1, Challenge.count
  end

  test "mistakes are reported by file and title, and nothing changes" do
    before = Challenge.count
    error = assert_raises(Challenge::InvalidFile) do
      with_files("animal_kingdom.yml" => <<~YAML) { Challenge.sync!(_1) }
        - {title: Lost, area: Narnia, difficulty: 1}
        - {title: Hard, difficulty: 5}
      YAML
    end
    assert_match "animal_kingdom.yml: Lost: Area Narnia isn't an area in Animal Kingdom", error.message
    assert_match "animal_kingdom.yml: Hard: Difficulty must be 1, 2 or 3", error.message
    assert_equal before, Challenge.count
  end

  test "file names must be anywhere or one of the tracker's parks" do
    error = assert_raises(Challenge::InvalidFile) do
      with_files("narnia.yml" => "- {title: Wardrobe, difficulty: 1}\n") { Challenge.sync!(_1) }
    end
    assert_match "narnia.yml: there's no park called that", error.message
    assert_match "sea_world.yml", error.message
  end

  test "Universal Orlando is one park with both parks' areas" do
    with_files("universal_orlando.yml" => <<~YAML) { Challenge.sync!(_1) }
      - {title: Gringotts, area: Diagon Alley, difficulty: 2}
      - {title: VelociCoaster, area: Jurassic Park, difficulty: 3}
    YAML
    assert_equal ["Universal Orlando"], Challenge.distinct.pluck(:park)

    error = assert_raises(Challenge::InvalidFile) do
      with_files("islands_of_adventure.yml" => "- {title: Hulk, difficulty: 1}\n") { Challenge.sync!(_1) }
    end
    assert_match "universal_orlando.yml", error.message
  end

  test "parks without a board can have challenges, but they aren't dealt" do
    with_files("epcot.yml" => "- {title: Soarin, area: World Nature, difficulty: 2}\n") { Challenge.sync!(_1) }

    assert_equal "Epcot", Challenge.find_by!(title: "Soarin").park
    assert_empty Challenge.for_park("Magic Kingdom").where(title: "Soarin")
  end

  test "duplicate titles, unknown fields and areas in anywhere.yml are rejected" do
    assert_raises(Challenge::InvalidFile) do
      with_files(
        "anywhere.yml" => "- {title: A, difficulty: 1}\n",
        "magic_kingdom.yml" => "- {title: A, difficulty: 2}\n",
      ) { Challenge.sync!(_1) }
    end

    error = assert_raises(Challenge::InvalidFile) do
      with_files("anywhere.yml" => "- {title: A, difficulty: 1, category: find}\n") { Challenge.sync!(_1) }
    end
    assert_match "unknown field category", error.message

    error = assert_raises(Challenge::InvalidFile) do
      with_files("anywhere.yml" => "- {title: A, difficulty: 1, area: Asia}\n") { Challenge.sync!(_1) }
    end
    assert_match "only works in a park's file", error.message
  end

  test "changed, added and deleted files are picked up on their own" do
    with_files("anywhere.yml" => "- {title: Old, difficulty: 1}\n") do |dir|
      Challenge.sync!(dir)

      write(dir, "anywhere.yml" => "- {title: New, difficulty: 1}\n", "magic_kingdom.yml" => "- {title: Castle, difficulty: 1}\n")
      assert_nil Challenge.refresh(dir)
      assert_equal %w[Castle New], Challenge.order(:title).pluck(:title)

      File.delete(File.join(dir, "magic_kingdom.yml"))
      later = (Time.current + 2.minutes).to_time
      File.utime(later, later, dir)
      assert_nil Challenge.refresh(dir)
      assert_equal %w[New], Challenge.pluck(:title)
    end
  end

  test "a broken file keeps the last good deck and reports the problem" do
    with_files("anywhere.yml" => "- {title: Good, difficulty: 1}\n") do |dir|
      Challenge.sync!(dir)
      write(dir, "anywhere.yml" => "- {title: Good, difficulty: 9}\n")

      assert_match "Difficulty must be 1, 2 or 3", Challenge.refresh(dir)
    end
    assert_equal 1, Challenge.find_by!(title: "Good").difficulty
  end
end
