require "test_helper"

class GameClockTest < ActiveSupport::TestCase
  test "advance counts only time inside windows" do
    day1 = Time.zone.parse("2026-10-01 09:00")
    clock = GameClock.new([[day1, day1 + 12.hours], [day1 + 1.day, day1 + 1.day + 12.hours]])

    assert_equal day1 + 30.minutes, clock.advance(day1, 30.minutes)
    assert_equal day1 + 1.day + 30.minutes, clock.advance(day1 + 11.5.hours, 1.hour)
    assert_nil clock.advance(day1 + 1.day + 11.hours, 2.hours)
    assert_equal day1 + 1.day + 12.hours, clock.ends_at
  end

  test "advance from before the first window starts at the window" do
    start = Time.zone.parse("2026-10-01 09:00")
    clock = GameClock.new([[start, start + 1.hour]])

    assert_equal start + 10.minutes, clock.advance(start - 3.hours, 10.minutes)
  end
end
