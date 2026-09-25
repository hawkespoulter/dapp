namespace :game do
  desc "Rebuild the park game challenge deck from config/game/challenges.yml and the tracker data"
  task sync_challenges: :environment do
    Challenge.sync!
    puts "#{Challenge.count} challenges (#{Challenge.where(source_type: nil).count} hand-written)"
  end
end
