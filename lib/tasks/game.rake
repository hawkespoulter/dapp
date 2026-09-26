namespace :game do
  desc "Load config/game/challenges/ now and report any problems (the app also loads the files on its own when they change)"
  task sync_challenges: :environment do
    Challenge.sync!
    counts = Challenge.group(:park).count.map { |park, n| "#{park || 'anywhere'}: #{n}" }
    puts "#{Challenge.count} challenges (#{counts.join(', ')})"
  end
end
