namespace :game do
  desc "Load config/game/challenges.yml now and report any problems (the app also loads it on its own when it changes)"
  task sync_challenges: :environment do
    Challenge.sync!
    counts = Challenge.group(:park).count.map { |park, n| "#{park || 'anywhere'}: #{n}" }
    puts "#{Challenge.count} challenges (#{counts.join(', ')})"
  end
end
