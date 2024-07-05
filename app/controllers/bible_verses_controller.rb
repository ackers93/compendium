class BibleVersesController < ApplicationController
  before_action :authenticate_user!

  OLD_TESTAMENT_BOOKS = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
    '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah',
    'Malachi'
  ].freeze

  NEW_TESTAMENT_BOOKS = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians',
    'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John', 'Jude', 'Revelation'
  ].freeze

  def book_index
    old_testament_order = OLD_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')
    new_testament_order = NEW_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')

    @old_testament_books = BibleVerse.select(:book).distinct.where(testament: 'OT').order(Arel.sql("CASE book #{old_testament_order} END"))
    @new_testament_books = BibleVerse.select(:book).distinct.where(testament: 'NT').order(Arel.sql("CASE book #{new_testament_order} END"))
  end

  def show
  end
end