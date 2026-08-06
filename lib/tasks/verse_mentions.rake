namespace :verse_mentions do
  desc "Backfill verse_mentions from existing note and comment ActionText bodies"
  task backfill: :environment do
    synced = 0
    mentions_before = VerseMention.count

    [Note, Comment].each do |klass|
      scope = klass.all
      total = scope.count
      puts "Syncing #{klass.name.pluralize} (#{total})..."

      scope.find_each.with_index(1) do |record, index|
        record.sync_verse_mentions
        synced += 1
        puts "  processed #{index}/#{total}" if (index % 100).zero? || index == total
      end
    end

    mentions_after = VerseMention.count
    puts "Done. Synced #{synced} records. Mentions: #{mentions_before} → #{mentions_after}."
  end
end
