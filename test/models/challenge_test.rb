require "test_helper"

class ChallengeTest < ActiveSupport::TestCase
  def with_file(yaml)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "challenges.yml")
      File.write(path, yaml)
      yield path
    end
  end

  test "the real challenges.yml loads cleanly" do
    Challenge.sync!
    assert Challenge.where(park: nil).exists?
  end

  test "the file is the whole deck: challenges are added, updated and removed" do
    with_file(<<~YAML) { Challenge.sync!(_1) }
      anywhere:
        - {title: Wave, category: social, difficulty: 1}
      Animal Kingdom:
        - {title: Yeti, area: Asia, category: find, difficulty: 2}
    YAML
    assert_equal %w[Wave Yeti], Challenge.order(:title).pluck(:title)
    assert_equal ["Animal Kingdom", "Asia"], Challenge.find_by(title: "Yeti").then { [_1.park, _1.area] }

    with_file(<<~YAML) { Challenge.sync!(_1) }
      anywhere:
        - {title: Yeti, category: find, difficulty: 3}
    YAML
    yeti = Challenge.find_by!(title: "Yeti")
    assert_equal [nil, nil, 3], [yeti.park, yeti.area, yeti.difficulty]
    assert_equal 1, Challenge.count
  end

  test "mistakes are reported by title and nothing changes" do
    before = Challenge.count
    error = assert_raises(Challenge::InvalidFile) do
      with_file(<<~YAML) { Challenge.sync!(_1) }
        Animal Kingdom:
          - {title: Lost, area: Narnia, category: find, difficulty: 1}
          - {title: Hard, category: find, difficulty: 5}
          - {title: Odd, category: dancing, difficulty: 1}
      YAML
    end
    assert_match "Lost: Area Narnia isn't an area in Animal Kingdom", error.message
    assert_match "Hard: Difficulty must be 1, 2 or 3", error.message
    assert_match "Odd: Category must be one of", error.message
    assert_equal before, Challenge.count
  end

  test "duplicate titles and unknown fields are rejected" do
    assert_raises(Challenge::InvalidFile) do
      with_file("anywhere:\n  - {title: A, category: find, difficulty: 1}\n  - {title: A, category: find, difficulty: 2}\n") { Challenge.sync!(_1) }
    end
    error = assert_raises(Challenge::InvalidFile) do
      with_file("anywhere:\n  - {title: A, category: find, difficulty: 1, coins: 4}\n") { Challenge.sync!(_1) }
    end
    assert_match "unknown field coins", error.message
  end

  test "a changed file is loaded again on its own" do
    with_file("anywhere:\n  - {title: Old, category: find, difficulty: 1}\n") do |path|
      Challenge.sync!(path)
      File.write(path, "anywhere:\n  - {title: New, category: find, difficulty: 1}\n")
      later = (Time.current + 1.minute).to_time
      File.utime(later, later, path)
      assert_nil Challenge.refresh(path)
    end
    assert_equal ["New"], Challenge.pluck(:title)
  end

  test "a broken file keeps the last good deck and reports the problem" do
    with_file("anywhere:\n  - {title: Good, category: find, difficulty: 1}\n") do |path|
      Challenge.sync!(path)
      File.write(path, "anywhere:\n  - {title: Good, category: find, difficulty: 9}\n")
      later = (Time.current + 1.minute).to_time
      File.utime(later, later, path)

      assert_match "Difficulty must be 1, 2 or 3", Challenge.refresh(path)
    end
    assert_equal 1, Challenge.find_by!(title: "Good").difficulty
  end
end
