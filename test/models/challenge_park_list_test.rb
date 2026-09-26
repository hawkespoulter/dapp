require "test_helper"

# Lists with a file per park (lists/geoguessr/animal_kingdom.yml), and photo
# items, as used by GeoGuessr.
class ChallengeParkListTest < ActiveSupport::TestCase
  def with_lists(files)
    Dir.mktmpdir do |dir|
      files.each do |name, yaml|
        path = File.join(dir, name)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, yaml)
      end
      yield Pathname(dir)
    end
  end

  def photo(n) = "- {image: https://example.test/#{n}.jpg, credit: Someone, answer: Place #{n}}\n"

  def geoguessr(lists_dir)
    Challenge.new(title: "GeoGuessr", reward: 2, list_from: "geoguessr", list_count: 1).tap { _1.lists_dir = lists_dir }
  end

  test "each park deals from its own photos" do
    with_lists("geoguessr/animal_kingdom.yml" => photo(1) + photo(2), "geoguessr/magic_kingdom.yml" => photo(3)) do |dir|
      challenge = geoguessr(dir)
      assert challenge.valid?

      ak = challenge.deal_list(Random.new(1), "Animal Kingdom")
      assert_equal 1, ak.size
      assert_includes %w[https://example.test/1.jpg https://example.test/2.jpg], ak.first["image"]
      assert_equal "https://example.test/3.jpg", challenge.deal_list(Random.new(1), "Magic Kingdom").first["image"]
    end
  end

  test "a park without photos isn't dealt the challenge" do
    with_lists("geoguessr/animal_kingdom.yml" => photo(1)) do |dir|
      challenge = geoguessr(dir)
      assert challenge.dealable_in?("Animal Kingdom")
      refute challenge.dealable_in?("Magic Kingdom")
    end
  end

  test "park list mistakes are reported" do
    with_lists("geoguessr/narnia.yml" => photo(1), "geoguessr/epcot.yml" => "- {credit: Someone}\n") do |dir|
      challenge = geoguessr(dir)
      refute challenge.valid?
      messages = challenge.errors.full_messages.to_sentence
      assert_match "lists/geoguessr/narnia.yml isn't named for a park", messages
      assert_match "lists/geoguessr/epcot.yml item 1 is a photo without an image", messages
    end
  end

  test "the real GeoGuessr photos are all valid" do
    challenge = Challenge.new(title: "GeoGuessr", reward: 2, list_from: "geoguessr", list_count: 1)
    skip "no GeoGuessr photos yet" unless challenge.per_park_list?

    assert challenge.valid?, challenge.errors.full_messages.to_sentence
  end
end
