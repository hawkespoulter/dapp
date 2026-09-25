# Game time only runs inside play windows (one window for a single-day game,
# one per day for multi-day). The villain acts every `interval` seconds of
# in-window time.
class GameClock
  attr_reader :windows

  # windows: array of [start_time, end_time]
  def initialize(windows)
    @windows = windows.map { |s, e| [Time.zone.parse(s.to_s), Time.zone.parse(e.to_s)] }.sort_by(&:first)
  end

  def ends_at
    windows.last&.last
  end

  def active?(time)
    windows.any? { |s, e| time >= s && time < e }
  end

  # The time reached by counting `seconds` of in-window time forward from
  # `from`. Returns nil if the windows run out first.
  def advance(from, seconds)
    remaining = seconds
    windows.each do |s, e|
      next if e <= from

      start = [s, from].max
      available = e - start
      return start + remaining if remaining <= available

      remaining -= available
    end
    nil
  end
end
