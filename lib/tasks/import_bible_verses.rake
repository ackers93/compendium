namespace :import do
    desc "Import Bible verses from text files"
    task bible_verses: :environment do
      require 'csv'
  
      # Define the testament and book order
      old_testament_books = [
        'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
        '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
        'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
        'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
        'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah',
        'Malachi'
      ]
  
      new_testament_books = [
        'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians',
        'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
        '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
        '1 John', '2 John', '3 John', 'Jude', 'Revelation'
      ]
  
      # Combine into a hash with testament
      book_testament = {}
      old_testament_books.each { |book| book_testament[book] = 'OT' }
      new_testament_books.each { |book| book_testament[book] = 'NT' }
  
      # Path to the folder containing the text files
      dir_path = Rails.root.join('public', 'KJV')
  
      total_verses_expected = 31102
      total_verses_imported = 0
  
      # Iterate over each file in the directory
      Dir.glob("#{dir_path}/*.txt") do |file_path|
        book_name = File.basename(file_path, '.txt')
        testament = book_testament[book_name]
  
        puts "Processing file: #{file_path} (Book: #{book_name}, Testament: #{testament})"
  
        # Read the entire file content
        file_content = File.read(file_path)
  
        # Parse the file content for verses
        verses_in_book = 0
  
        file_content.scan(/\{(\d+):(\d+)\}(.*?)(?=\{\d+:\d+\}|\z)/m).each do |chapter, verse, text|
          verses_in_book += 1
  
          begin
            bible_verse = BibleVerse.create!(
              book: book_name,
              chapter: chapter.to_i,
              verse: verse.to_i,
              text: text.strip,
              testament: testament
            )
            total_verses_imported += 1
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to create verse #{chapter}:#{verse} in #{book_name} - #{e.message}"
          end
        end
  
        puts "Verses in #{book_name}: #{verses_in_book}"
      end
  
      puts "Total verses imported: #{total_verses_imported}"
      puts "Expected verses: #{total_verses_expected}"
      missing_verses = total_verses_expected - total_verses_imported
      puts "Missing verses: #{missing_verses}" if missing_verses > 0
  
      if missing_verses > 0
        puts "Please review the logs for missing verses and ensure all files are correctly formatted and complete."
      else
        puts "All verses imported successfully."
      end
    end
  end
  