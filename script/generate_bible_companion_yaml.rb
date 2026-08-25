# frozen_string_literal: true

# Generates db/data/reading_plans/bible_companion.yml from the classic
# Robert Roberts Bible Companion schedule (minus the Agora Proverbs column).
# Run: ruby script/generate_bible_companion_yaml.rb

require "yaml"
require "pathname"

ROOT = Pathname.new(__dir__).join("..")
OUT = ROOT.join("db/data/reading_plans/bible_companion.yml")

BOOKS = {
  "Gen" => "Genesis",
  "Exo" => "Exodus",
  "Lev" => "Leviticus",
  "Num" => "Numbers",
  "Deu" => "Deuteronomy",
  "Jos" => "Joshua",
  "Jdg" => "Judges",
  "Rth" => "Ruth",
  "1Sa" => "1 Samuel",
  "2Sa" => "2 Samuel",
  "1Ki" => "1 Kings",
  "2Ki" => "2 Kings",
  "1Ch" => "1 Chronicles",
  "2Ch" => "2 Chronicles",
  "Ezr" => "Ezra",
  "Neh" => "Nehemiah",
  "Est" => "Esther",
  "Job" => "Job",
  "Psa" => "Psalms",
  "Pro" => "Proverbs",
  "Ecc" => "Ecclesiastes",
  "Song" => "Song of Solomon",
  "Isa" => "Isaiah",
  "Jer" => "Jeremiah",
  "Lam" => "Lamentations",
  "Eze" => "Ezekiel",
  "Dan" => "Daniel",
  "Hos" => "Hosea",
  "Joel" => "Joel",
  "Amo" => "Amos",
  "Oba" => "Obadiah",
  "Jon" => "Jonah",
  "Mic" => "Micah",
  "Nah" => "Nahum",
  "Hab" => "Habakkuk",
  "Zep" => "Zephaniah",
  "Hag" => "Haggai",
  "Zec" => "Zechariah",
  "Mal" => "Malachi",
  "Mat" => "Matthew",
  "Mar" => "Mark",
  "Luk" => "Luke",
  "Joh" => "John",
  "Act" => "Acts",
  "Rom" => "Romans",
  "1Co" => "1 Corinthians",
  "2Co" => "2 Corinthians",
  "Gal" => "Galatians",
  "Eph" => "Ephesians",
  "Phi" => "Philippians",
  "Col" => "Colossians",
  "1Th" => "1 Thessalonians",
  "2Th" => "2 Thessalonians",
  "1Ti" => "1 Timothy",
  "2Ti" => "2 Timothy",
  "Tit" => "Titus",
  "Phm" => "Philemon",
  "Heb" => "Hebrews",
  "Jam" => "James",
  "1Pe" => "1 Peter",
  "2Pe" => "2 Peter",
  "1Jo" => "1 John",
  "2Jo" => "2 John",
  "3Jo" => "3 John",
  "Jud" => "Jude",
  "Rev" => "Revelation"
}.freeze

# month => [[day, r1, r2, r3], ...]
# Source: classic Bible Companion (Agora chart), with corrections:
# - Psalm 119 portions use traditional 1-40 / 41-80 / 81-128 / 129-176
# - Nov 26 NT is 2Ti 3,4 (not 2Th)
# - Dec 2 poetry is Jon 2,3 (not Jon 3,4)
SCHEDULE = {
  1 => [
    [1, "Gen 1, 2", "Psa 1, 2", "Mat 1, 2"],
    [2, "Gen 3, 4", "Psa 3-5", "Mat 3, 4"],
    [3, "Gen 5, 6", "Psa 6-8", "Mat 5"],
    [4, "Gen 7, 8", "Psa 9, 10", "Mat 6"],
    [5, "Gen 9, 10", "Psa 11-13", "Mat 7"],
    [6, "Gen 11, 12", "Psa 14-16", "Mat 8"],
    [7, "Gen 13, 14", "Psa 17", "Mat 9"],
    [8, "Gen 15, 16", "Psa 18", "Mat 10"],
    [9, "Gen 17, 18", "Psa 19-21", "Mat 11"],
    [10, "Gen 19", "Psa 22", "Mat 12"],
    [11, "Gen 20, 21", "Psa 23-25", "Mat 13"],
    [12, "Gen 22, 23", "Psa 26-28", "Mat 14"],
    [13, "Gen 24", "Psa 29, 30", "Mat 15"],
    [14, "Gen 25, 26", "Psa 31", "Mat 16"],
    [15, "Gen 27", "Psa 32", "Mat 17"],
    [16, "Gen 28, 29", "Psa 33", "Mat 18"],
    [17, "Gen 30", "Psa 34", "Mat 19"],
    [18, "Gen 31", "Psa 35", "Mat 20"],
    [19, "Gen 32, 33", "Psa 36", "Mat 21"],
    [20, "Gen 34, 35", "Psa 37", "Mat 22"],
    [21, "Gen 36", "Psa 38", "Mat 23"],
    [22, "Gen 37", "Psa 39, 40", "Mat 24"],
    [23, "Gen 38", "Psa 41-43", "Mat 25"],
    [24, "Gen 39, 40", "Psa 44", "Mat 26"],
    [25, "Gen 41", "Psa 45", "Mat 27"],
    [26, "Gen 42, 43", "Psa 46-48", "Mat 28"],
    [27, "Gen 44, 45", "Psa 49", "Rom 1, 2"],
    [28, "Gen 46, 47", "Psa 50", "Rom 3, 4"],
    [29, "Gen 48-50", "Psa 51, 52", "Rom 5, 6"],
    [30, "Exo 1, 2", "Psa 53-55", "Rom 7, 8"],
    [31, "Exo 3, 4", "Psa 56, 57", "Rom 9"]
  ],
  2 => [
    [1, "Exo 5, 6", "Psa 58, 59", "Rom 10, 11"],
    [2, "Exo 7, 8", "Psa 60, 61", "Rom 12"],
    [3, "Exo 9", "Psa 62, 63", "Rom 13, 14"],
    [4, "Exo 10", "Psa 64, 65", "Rom 15, 16"],
    [5, "Exo 11, 12", "Psa 66, 67", "Mar 1"],
    [6, "Exo 13, 14", "Psa 68", "Mar 2"],
    [7, "Exo 15", "Psa 69", "Mar 3"],
    [8, "Exo 16", "Psa 70, 71", "Mar 4"],
    [9, "Exo 17, 18", "Psa 72", "Mar 5"],
    [10, "Exo 19, 20", "Psa 73", "Mar 6"],
    [11, "Exo 21", "Psa 74", "Mar 7"],
    [12, "Exo 22", "Psa 75, 76", "Mar 8"],
    [13, "Exo 23", "Psa 77", "Mar 9"],
    [14, "Exo 24, 25", "Psa 78", "Mar 10"],
    [15, "Exo 26", "Psa 79, 80", "Mar 11"],
    [16, "Exo 27", "Psa 81, 82", "Mar 12"],
    [17, "Exo 28", "Psa 83, 84", "Mar 13"],
    [18, "Exo 29", "Psa 85, 86", "Mar 14"],
    [19, "Exo 30", "Psa 87, 88", "Mar 15, 16"],
    [20, "Exo 31, 32", "Psa 89", "1Co 1, 2"],
    [21, "Exo 33, 34", "Psa 90, 91", "1Co 3"],
    [22, "Exo 35", "Psa 92, 93", "1Co 4, 5"],
    [23, "Exo 36", "Psa 94, 95", "1Co 6"],
    [24, "Exo 37", "Psa 96-99", "1Co 7"],
    [25, "Exo 38", "Psa 100, 101", "1Co 8, 9"],
    [26, "Exo 39, 40", "Psa 102", "1Co 10"],
    [27, "Lev 1, 2", "Psa 103", "1Co 11"],
    [28, "Lev 3, 4", "Psa 104", "1Co 12, 13"]
  ],
  3 => [
    [1, "Lev 5, 6", "Psa 105", "1Co 14"],
    [2, "Lev 7", "Psa 106", "1Co 15"],
    [3, "Lev 8", "Psa 107", "1Co 16"],
    [4, "Lev 9, 10", "Psa 108, 109", "2Co 1, 2"],
    [5, "Lev 11", "Psa 110-112", "2Co 3, 4"],
    [6, "Lev 12, 13", "Psa 113, 114", "2Co 5-7"],
    [7, "Lev 14", "Psa 115, 116", "2Co 8, 9"],
    [8, "Lev 15", "Psa 117, 118", "2Co 10, 11"],
    [9, "Lev 16", "Psa 119:1-40", "2Co 12, 13"],
    [10, "Lev 17, 18", "Psa 119:41-80", "Luk 1"],
    [11, "Lev 19", "Psa 119:81-128", "Luk 2"],
    [12, "Lev 20", "Psa 119:129-176", "Luk 3"],
    [13, "Lev 21", "Psa 120-124", "Luk 4"],
    [14, "Lev 22", "Psa 125-127", "Luk 5"],
    [15, "Lev 23", "Psa 128-130", "Luk 6"],
    [16, "Lev 24", "Psa 131-134", "Luk 7"],
    [17, "Lev 25", "Psa 135, 136", "Luk 8"],
    [18, "Lev 26", "Psa 137-139", "Luk 9"],
    [19, "Lev 27", "Psa 140-142", "Luk 10"],
    [20, "Num 1", "Psa 143, 144", "Luk 11"],
    [21, "Num 2", "Psa 145-147", "Luk 12"],
    [22, "Num 3", "Psa 148-150", "Luk 13, 14"],
    [23, "Num 4", "Pro 1", "Luk 15"],
    [24, "Num 5", "Pro 2", "Luk 16"],
    [25, "Num 6", "Pro 3", "Luk 17"],
    [26, "Num 7", "Pro 4", "Luk 18"],
    [27, "Num 8, 9", "Pro 5", "Luk 19"],
    [28, "Num 10", "Pro 6", "Luk 20"],
    [29, "Num 11", "Pro 7", "Luk 21"],
    [30, "Num 12, 13", "Pro 8, 9", "Luk 22"],
    [31, "Num 14", "Pro 10", "Luk 23"]
  ],
  4 => [
    [1, "Num 15", "Pro 11", "Luk 24"],
    [2, "Num 16", "Pro 12", "Gal 1, 2"],
    [3, "Num 17, 18", "Pro 13", "Gal 3, 4"],
    [4, "Num 19", "Pro 14", "Gal 5, 6"],
    [5, "Num 20, 21", "Pro 15", "Eph 1, 2"],
    [6, "Num 22, 23", "Pro 16", "Eph 3, 4"],
    [7, "Num 24, 25", "Pro 17", "Eph 5, 6"],
    [8, "Num 26", "Pro 18", "Phi 1, 2"],
    [9, "Num 27", "Pro 19", "Phi 3, 4"],
    [10, "Num 28", "Pro 20", "Joh 1"],
    [11, "Num 29, 30", "Pro 21", "Joh 2, 3"],
    [12, "Num 31", "Pro 22", "Joh 4"],
    [13, "Num 32", "Pro 23", "Joh 5"],
    [14, "Num 33", "Pro 24", "Joh 6"],
    [15, "Num 34", "Pro 25", "Joh 7"],
    [16, "Num 35", "Pro 26", "Joh 8"],
    [17, "Num 36", "Pro 27", "Joh 9, 10"],
    [18, "Deu 1", "Pro 28", "Joh 11"],
    [19, "Deu 2", "Pro 29", "Joh 12"],
    [20, "Deu 3", "Pro 30", "Joh 13, 14"],
    [21, "Deu 4", "Pro 31", "Joh 15, 16"],
    [22, "Deu 5", "Ecc 1", "Joh 17, 18"],
    [23, "Deu 6, 7", "Ecc 2", "Joh 19"],
    [24, "Deu 8, 9", "Ecc 3", "Joh 20, 21"],
    [25, "Deu 10, 11", "Ecc 4", "Act 1"],
    [26, "Deu 12", "Ecc 5", "Act 2"],
    [27, "Deu 13, 14", "Ecc 6", "Act 3, 4"],
    [28, "Deu 15", "Ecc 7", "Act 5, 6"],
    [29, "Deu 16", "Ecc 8", "Act 7"],
    [30, "Deu 17", "Ecc 9", "Act 8"]
  ],
  5 => [
    [1, "Deu 18", "Ecc 10", "Act 9"],
    [2, "Deu 19", "Ecc 11", "Act 10"],
    [3, "Deu 20", "Ecc 12", "Act 11, 12"],
    [4, "Deu 21", "Song 1", "Act 13"],
    [5, "Deu 22", "Song 2", "Act 14, 15"],
    [6, "Deu 23", "Song 3", "Act 16, 17"],
    [7, "Deu 24", "Song 4", "Act 18, 19"],
    [8, "Deu 25", "Song 5", "Act 20"],
    [9, "Deu 26", "Song 6", "Act 21, 22"],
    [10, "Deu 27", "Song 7", "Act 23, 24"],
    [11, "Deu 28", "Song 8", "Act 25, 26"],
    [12, "Deu 29", "Isa 1", "Act 27"],
    [13, "Deu 30", "Isa 2", "Act 28"],
    [14, "Deu 31", "Isa 3, 4", "Col 1"],
    [15, "Deu 32", "Isa 5", "Col 2"],
    [16, "Deu 33, 34", "Isa 6", "Col 3, 4"],
    [17, "Jos 1", "Isa 7", "1Th 1, 2"],
    [18, "Jos 2", "Isa 8", "1Th 3, 4"],
    [19, "Jos 3, 4", "Isa 9", "1Th 5"],
    [20, "Jos 5, 6", "Isa 10", "2Th 1, 2"],
    [21, "Jos 7", "Isa 11", "2Th 3"],
    [22, "Jos 8", "Isa 12", "1Ti 1-3"],
    [23, "Jos 9", "Isa 13", "1Ti 4, 5"],
    [24, "Jos 10", "Isa 14", "1Ti 6"],
    [25, "Jos 11", "Isa 15", "2Ti 1"],
    [26, "Jos 12", "Isa 16", "2Ti 2"],
    [27, "Jos 13", "Isa 17, 18", "2Ti 3, 4"],
    [28, "Jos 14", "Isa 19", "Tit 1-3"],
    [29, "Jos 15", "Isa 20, 21", "Phm"],
    [30, "Jos 16", "Isa 22", "Heb 1, 2"],
    [31, "Jos 17", "Isa 23", "Heb 3-5"]
  ],
  6 => [
    [1, "Jos 18", "Isa 24", "Heb 6, 7"],
    [2, "Jos 19", "Isa 25", "Heb 8, 9"],
    [3, "Jos 20, 21", "Isa 26, 27", "Heb 10"],
    [4, "Jos 22", "Isa 28", "Heb 11"],
    [5, "Jos 23, 24", "Isa 29", "Heb 12"],
    [6, "Jdg 1", "Isa 30", "Heb 13"],
    [7, "Jdg 2, 3", "Isa 31", "Jam 1"],
    [8, "Jdg 4, 5", "Isa 32", "Jam 2"],
    [9, "Jdg 6", "Isa 33", "Jam 3, 4"],
    [10, "Jdg 7, 8", "Isa 34", "Jam 5"],
    [11, "Jdg 9", "Isa 35", "1Pe 1"],
    [12, "Jdg 10, 11", "Isa 36", "1Pe 2"],
    [13, "Jdg 12, 13", "Isa 37", "1Pe 3-5"],
    [14, "Jdg 14, 15", "Isa 38", "2Pe 1, 2"],
    [15, "Jdg 16", "Isa 39", "2Pe 3"],
    [16, "Jdg 17, 18", "Isa 40", "1Jo 1, 2"],
    [17, "Jdg 19", "Isa 41", "1Jo 3, 4"],
    [18, "Jdg 20", "Isa 42", "1Jo 5"],
    [19, "Jdg 21", "Isa 43", "2Jo, 3Jo"],
    [20, "Rth 1, 2", "Isa 44", "Jud"],
    [21, "Rth 3, 4", "Isa 45", "Rev 1, 2"],
    [22, "1Sa 1", "Isa 46, 47", "Rev 3, 4"],
    [23, "1Sa 2", "Isa 48", "Rev 5, 6"],
    [24, "1Sa 3", "Isa 49", "Rev 7-9"],
    [25, "1Sa 4", "Isa 50", "Rev 10, 11"],
    [26, "1Sa 5, 6", "Isa 51", "Rev 12, 13"],
    [27, "1Sa 7, 8", "Isa 52", "Rev 14"],
    [28, "1Sa 9", "Isa 53", "Rev 15, 16"],
    [29, "1Sa 10", "Isa 54", "Rev 17, 18"],
    [30, "1Sa 11, 12", "Isa 55", "Rev 19, 20"]
  ],
  7 => [
    [1, "1Sa 13", "Isa 56, 57", "Rev 21, 22"],
    [2, "1Sa 14", "Isa 58", "Mat 1, 2"],
    [3, "1Sa 15", "Isa 59", "Mat 3, 4"],
    [4, "1Sa 16", "Isa 60", "Mat 5"],
    [5, "1Sa 17", "Isa 61", "Mat 6"],
    [6, "1Sa 18", "Isa 62", "Mat 7"],
    [7, "1Sa 19", "Isa 63", "Mat 8"],
    [8, "1Sa 20", "Isa 64", "Mat 9"],
    [9, "1Sa 21, 22", "Isa 65", "Mat 10"],
    [10, "1Sa 23", "Isa 66", "Mat 11"],
    [11, "1Sa 24", "Jer 1", "Mat 12"],
    [12, "1Sa 25", "Jer 2", "Mat 13"],
    [13, "1Sa 26, 27", "Jer 3", "Mat 14"],
    [14, "1Sa 28", "Jer 4", "Mat 15"],
    [15, "1Sa 29, 30", "Jer 5", "Mat 16"],
    [16, "1Sa 31", "Jer 6", "Mat 17"],
    [17, "2Sa 1", "Jer 7", "Mat 18"],
    [18, "2Sa 2", "Jer 8", "Mat 19"],
    [19, "2Sa 3", "Jer 9", "Mat 20"],
    [20, "2Sa 4, 5", "Jer 10", "Mat 21"],
    [21, "2Sa 6", "Jer 11", "Mat 22"],
    [22, "2Sa 7", "Jer 12", "Mat 23"],
    [23, "2Sa 8, 9", "Jer 13", "Mat 24"],
    [24, "2Sa 10", "Jer 14", "Mat 25"],
    [25, "2Sa 11", "Jer 15", "Mat 26"],
    [26, "2Sa 12", "Jer 16", "Mat 27"],
    [27, "2Sa 13", "Jer 17", "Mat 28"],
    [28, "2Sa 14", "Jer 18", "Rom 1, 2"],
    [29, "2Sa 15", "Jer 19", "Rom 3, 4"],
    [30, "2Sa 16", "Jer 20", "Rom 5, 6"],
    [31, "2Sa 17", "Jer 21", "Rom 7, 8"]
  ],
  8 => [
    [1, "2Sa 18", "Jer 22", "Rom 9"],
    [2, "2Sa 19", "Jer 23", "Rom 10, 11"],
    [3, "2Sa 20, 21", "Jer 24", "Rom 12"],
    [4, "2Sa 22", "Jer 25", "Rom 13, 14"],
    [5, "2Sa 23", "Jer 26", "Rom 15, 16"],
    [6, "2Sa 24", "Jer 27", "Mar 1"],
    [7, "1Ki 1", "Jer 28", "Mar 2"],
    [8, "1Ki 2", "Jer 29", "Mar 3"],
    [9, "1Ki 3", "Jer 30", "Mar 4"],
    [10, "1Ki 4, 5", "Jer 31", "Mar 5"],
    [11, "1Ki 6", "Jer 32", "Mar 6"],
    [12, "1Ki 7", "Jer 33", "Mar 7"],
    [13, "1Ki 8", "Jer 34", "Mar 8"],
    [14, "1Ki 9", "Jer 35", "Mar 9"],
    [15, "1Ki 10", "Jer 36", "Mar 10"],
    [16, "1Ki 11", "Jer 37", "Mar 11"],
    [17, "1Ki 12", "Jer 38", "Mar 12"],
    [18, "1Ki 13", "Jer 39", "Mar 13"],
    [19, "1Ki 14", "Jer 40", "Mar 14"],
    [20, "1Ki 15", "Jer 41", "Mar 15"],
    [21, "1Ki 16", "Jer 42", "Mar 16"],
    [22, "1Ki 17", "Jer 43", "1Co 1, 2"],
    [23, "1Ki 18", "Jer 44", "1Co 3"],
    [24, "1Ki 19", "Jer 45, 46", "1Co 4, 5"],
    [25, "1Ki 20", "Jer 47", "1Co 6"],
    [26, "1Ki 21", "Jer 48", "1Co 7"],
    [27, "1Ki 22", "Jer 49", "1Co 8, 9"],
    [28, "2Ki 1, 2", "Jer 50", "1Co 10"],
    [29, "2Ki 3", "Jer 51", "1Co 11"],
    [30, "2Ki 4", "Jer 52", "1Co 12, 13"],
    [31, "2Ki 5", "Lam 1", "1Co 14"]
  ],
  9 => [
    [1, "2Ki 6", "Lam 2", "1Co 15"],
    [2, "2Ki 7", "Lam 3", "1Co 16"],
    [3, "2Ki 8", "Lam 4", "2Co 1, 2"],
    [4, "2Ki 9", "Lam 5", "2Co 3, 4"],
    [5, "2Ki 10", "Eze 1", "2Co 5-7"],
    [6, "2Ki 11, 12", "Eze 2", "2Co 8, 9"],
    [7, "2Ki 13", "Eze 3", "2Co 10, 11"],
    [8, "2Ki 14", "Eze 4", "2Co 12, 13"],
    [9, "2Ki 15", "Eze 5", "Luk 1"],
    [10, "2Ki 16", "Eze 6", "Luk 2"],
    [11, "2Ki 17", "Eze 7", "Luk 3"],
    [12, "2Ki 18", "Eze 8", "Luk 4"],
    [13, "2Ki 19", "Eze 9", "Luk 5"],
    [14, "2Ki 20", "Eze 10", "Luk 6"],
    [15, "2Ki 21", "Eze 11", "Luk 7"],
    [16, "2Ki 22, 23", "Eze 12", "Luk 8"],
    [17, "2Ki 24, 25", "Eze 13", "Luk 9"],
    [18, "1Ch 1", "Eze 14", "Luk 10"],
    [19, "1Ch 2", "Eze 15", "Luk 11"],
    [20, "1Ch 3", "Eze 16", "Luk 12"],
    [21, "1Ch 4", "Eze 17", "Luk 13, 14"],
    [22, "1Ch 5", "Eze 18", "Luk 15"],
    [23, "1Ch 6", "Eze 19", "Luk 16"],
    [24, "1Ch 7", "Eze 20", "Luk 17"],
    [25, "1Ch 8", "Eze 21", "Luk 18"],
    [26, "1Ch 9", "Eze 22", "Luk 19"],
    [27, "1Ch 10", "Eze 23", "Luk 20"],
    [28, "1Ch 11", "Eze 24", "Luk 21"],
    [29, "1Ch 12", "Eze 25", "Luk 22"],
    [30, "1Ch 13, 14", "Eze 26", "Luk 23"]
  ],
  10 => [
    [1, "1Ch 15", "Eze 27", "Luk 24"],
    [2, "1Ch 16", "Eze 28", "Gal 1, 2"],
    [3, "1Ch 17", "Eze 29", "Gal 3, 4"],
    [4, "1Ch 18, 19", "Eze 30", "Gal 5, 6"],
    [5, "1Ch 20, 21", "Eze 31", "Eph 1, 2"],
    [6, "1Ch 22", "Eze 32", "Eph 3, 4"],
    [7, "1Ch 23", "Eze 33", "Eph 5, 6"],
    [8, "1Ch 24, 25", "Eze 34", "Phi 1, 2"],
    [9, "1Ch 26", "Eze 35", "Phi 3, 4"],
    [10, "1Ch 27", "Eze 36", "Joh 1"],
    [11, "1Ch 28", "Eze 37", "Joh 2, 3"],
    [12, "1Ch 29", "Eze 38", "Joh 4"],
    [13, "2Ch 1, 2", "Eze 39", "Joh 5"],
    [14, "2Ch 3, 4", "Eze 40", "Joh 6"],
    [15, "2Ch 5, 6", "Eze 41", "Joh 7"],
    [16, "2Ch 7", "Eze 42", "Joh 8"],
    [17, "2Ch 8", "Eze 43", "Joh 9, 10"],
    [18, "2Ch 9", "Eze 44", "Joh 11"],
    [19, "2Ch 10, 11", "Eze 45", "Joh 12"],
    [20, "2Ch 12, 13", "Eze 46", "Joh 13, 14"],
    [21, "2Ch 14, 15", "Eze 47", "Joh 15, 16"],
    [22, "2Ch 16, 17", "Eze 48", "Joh 17, 18"],
    [23, "2Ch 18, 19", "Dan 1", "Joh 19"],
    [24, "2Ch 20", "Dan 2", "Joh 20, 21"],
    [25, "2Ch 21, 22", "Dan 3", "Act 1"],
    [26, "2Ch 23", "Dan 4", "Act 2"],
    [27, "2Ch 24", "Dan 5", "Act 3, 4"],
    [28, "2Ch 25", "Dan 6", "Act 5, 6"],
    [29, "2Ch 26, 27", "Dan 7", "Act 7"],
    [30, "2Ch 28", "Dan 8", "Act 8"],
    [31, "2Ch 29", "Dan 9", "Act 9"]
  ],
  11 => [
    [1, "2Ch 30", "Dan 10", "Act 10"],
    [2, "2Ch 31", "Dan 11", "Act 11, 12"],
    [3, "2Ch 32", "Dan 12", "Act 13"],
    [4, "2Ch 33", "Hos 1", "Act 14, 15"],
    [5, "2Ch 34", "Hos 2", "Act 16, 17"],
    [6, "2Ch 35", "Hos 3", "Act 18, 19"],
    [7, "2Ch 36", "Hos 4", "Act 20"],
    [8, "Ezr 1, 2", "Hos 5", "Act 21, 22"],
    [9, "Ezr 3, 4", "Hos 6", "Act 23, 24"],
    [10, "Ezr 5, 6", "Hos 7", "Act 25, 26"],
    [11, "Ezr 7", "Hos 8", "Act 27"],
    [12, "Ezr 8", "Hos 9", "Act 28"],
    [13, "Ezr 9", "Hos 10", "Col 1"],
    [14, "Ezr 10", "Hos 11", "Col 2"],
    [15, "Neh 1, 2", "Hos 12", "Col 3, 4"],
    [16, "Neh 3", "Hos 13", "1Th 1, 2"],
    [17, "Neh 4", "Hos 14", "1Th 3, 4"],
    [18, "Neh 5, 6", "Joel 1", "1Th 5"],
    [19, "Neh 7", "Joel 2", "2Th 1, 2"],
    [20, "Neh 8", "Joel 3", "2Th 3"],
    [21, "Neh 9", "Amo 1", "1Ti 1-3"],
    [22, "Neh 10", "Amo 2", "1Ti 4, 5"],
    [23, "Neh 11", "Amo 3", "1Ti 6"],
    [24, "Neh 12", "Amo 4", "2Ti 1"],
    [25, "Neh 13", "Amo 5", "2Ti 2"],
    [26, "Est 1", "Amo 6", "2Ti 3, 4"],
    [27, "Est 2", "Amo 7", "Tit 1-3"],
    [28, "Est 3, 4", "Amo 8", "Phm"],
    [29, "Est 5, 6", "Amo 9", "Heb 1, 2"],
    [30, "Est 7, 8", "Oba", "Heb 3-5"]
  ],
  12 => [
    [1, "Est 9, 10", "Jon 1", "Heb 6, 7"],
    [2, "Job 1, 2", "Jon 2, 3", "Heb 8, 9"],
    [3, "Job 3, 4", "Jon 4", "Heb 10"],
    [4, "Job 5", "Mic 1", "Heb 11"],
    [5, "Job 6, 7", "Mic 2", "Heb 12"],
    [6, "Job 8", "Mic 3, 4", "Heb 13"],
    [7, "Job 9", "Mic 5", "Jam 1"],
    [8, "Job 10", "Mic 6", "Jam 2"],
    [9, "Job 11", "Mic 7", "Jam 3, 4"],
    [10, "Job 12", "Nah 1, 2", "Jam 5"],
    [11, "Job 13", "Nah 3", "1Pe 1"],
    [12, "Job 14", "Hab 1", "1Pe 2"],
    [13, "Job 15", "Hab 2", "1Pe 3-5"],
    [14, "Job 16, 17", "Hab 3", "2Pe 1, 2"],
    [15, "Job 18, 19", "Zep 1", "2Pe 3"],
    [16, "Job 20", "Zep 2", "1Jo 1, 2"],
    [17, "Job 21", "Zep 3", "1Jo 3, 4"],
    [18, "Job 22", "Hag 1, 2", "1Jo 5"],
    [19, "Job 23, 24", "Zec 1", "2Jo, 3Jo"],
    [20, "Job 25-27", "Zec 2, 3", "Jud"],
    [21, "Job 28", "Zec 4, 5", "Rev 1, 2"],
    [22, "Job 29, 30", "Zec 6, 7", "Rev 3, 4"],
    [23, "Job 31, 32", "Zec 8", "Rev 5, 6"],
    [24, "Job 33", "Zec 9", "Rev 7-9"],
    [25, "Job 34", "Zec 10", "Rev 10, 11"],
    [26, "Job 35, 36", "Zec 11", "Rev 12, 13"],
    [27, "Job 37", "Zec 12", "Rev 14"],
    [28, "Job 38", "Zec 13, 14", "Rev 15, 16"],
    [29, "Job 39", "Mal 1", "Rev 17, 18"],
    [30, "Job 40", "Mal 2", "Rev 19, 20"],
    [31, "Job 41, 42", "Mal 3, 4", "Rev 21, 22"]
  ]
}.freeze

SINGLE_CHAPTER_BOOKS = %w[Obadiah Philemon 2\ John 3\ John Jude].freeze

def expand_chapters(spec)
  spec = spec.strip
  if spec.include?("-")
    a, b = spec.split("-", 2).map { |n| Integer(n.strip) }
    (a..b).to_a
  else
    [Integer(spec)]
  end
end

def parse_slot(raw)
  raw = raw.strip.gsub("´", "")
  passages = []

  # Split multiple books joined by comma only when both sides look like book refs
  # e.g. "2Jo, 3Jo"
  parts = raw.split(/,\s*(?=[A-Za-z0-9])/).map(&:strip)

  # Re-merge chapter lists that were split: "Gen 1" + "2" => handled differently
  # Actually "Gen 1, 2" splits badly. Better approach: tokenize by book abbr.

  tokens = []
  buffer = ""
  raw.split(",").each do |chunk|
    chunk = chunk.strip
    if chunk.match?(/\A[123]?[A-Za-z]/)
      tokens << buffer unless buffer.empty?
      buffer = chunk
    else
      buffer = buffer.empty? ? chunk : "#{buffer}, #{chunk}"
    end
  end
  tokens << buffer unless buffer.empty?

  tokens.each do |token|
    token = token.strip
    if (m = token.match(/\A([123]?[A-Za-z]+)\s+(\d+):(\d+)-(\d+)\z/))
      abbr, chapter, vs, ve = m[1], m[2].to_i, m[3].to_i, m[4].to_i
      book = BOOKS.fetch(abbr)
      passages << {
        "book" => book,
        "start_chapter" => chapter,
        "end_chapter" => chapter,
        "start_verse" => vs,
        "end_verse" => ve
      }
    elsif (m = token.match(/\A([123]?[A-Za-z]+)\s+(.+)\z/))
      abbr = m[1]
      chapter_spec = m[2].gsub(/\s+/, "")
      book = BOOKS.fetch(abbr)
      chapters = chapter_spec.split(",").flat_map { |c| expand_chapters(c) }
      passages << {
        "book" => book,
        "start_chapter" => chapters.first,
        "end_chapter" => chapters.last
      }
    elsif token.match?(/\A[123]?[A-Za-z]+\z/)
      abbr = token
      book = BOOKS.fetch(abbr)
      raise "Expected single-chapter book for #{book}" unless SINGLE_CHAPTER_BOOKS.include?(book)
      passages << {
        "book" => book,
        "start_chapter" => 1,
        "end_chapter" => 1
      }
    else
      raise "Unparseable token: #{token.inspect} in #{raw.inspect}"
    end
  end

  passages
end

days = []
SCHEDULE.each do |month, entries|
  entries.each do |day, r1, r2, r3|
    readings = [r1, r2, r3].each_with_index.map do |raw, idx|
      {
        "slot" => idx + 1,
        "passages" => parse_slot(raw)
      }
    end
    days << {
      "month" => month,
      "day" => day,
      "readings" => readings
    }
  end
end

raise "Expected 365 days, got #{days.size}" unless days.size == 365

doc = {
  "slug" => "bible-companion",
  "name" => "Bible Companion",
  "description" =>
    "The daily Bible reading plan compiled by Robert Roberts (the Bible Companion). " \
    "Three readings each day cover the Old Testament once and the New Testament twice each year. " \
    "February 29 has no assigned readings and may be used as a catch-up day.",
  "days" => days
}

OUT.dirname.mkpath
OUT.write(YAML.dump(doc))
puts "Wrote #{days.size} days to #{OUT}"
