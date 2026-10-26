namespace :game do
  desc "Load any challenge, list and claim files not loaded yet (the app also does this on its own) and report problems"
  task seed_content: :environment do
    problem = GameContent.seed!
    counts = Challenge.group(:park).count.map { |park, n| "#{park || 'anywhere'}: #{n}" }
    puts "#{Challenge.count} challenges (#{counts.join(', ')}), #{ClaimChallenge.count} claim cards, #{ChallengeList.count} lists"
    puts problem if problem
  end
end
