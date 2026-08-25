# Preview all emails at http://localhost:3000/rails/mailers/weekly_digest_mailer
class WeeklyDigestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/weekly_digest_mailer/digest
  def digest
    user = User.new(
      id: 1,
      email: "reader@example.com",
      name: "Jane Reader"
    )

    range = WeeklyDigestCollector.previous_week_range
    summary = [
      WeeklyDigestCollector::Section.new(
        key: :notes,
        label: "Notes",
        count: 2,
        examples: [
          WeeklyDigestCollector::Example.new(title: "Faith and works", url: "http://localhost:3000/notes/1"),
          WeeklyDigestCollector::Example.new(title: "On prayer", url: "http://localhost:3000/notes/2")
        ],
        contribute_path: "http://localhost:3000/notes/new"
      ),
      WeeklyDigestCollector::Section.new(
        key: :comments,
        label: "Comments",
        count: 0,
        examples: [],
        contribute_path: "http://localhost:3000/bible_verses/books"
      ),
      WeeklyDigestCollector::Section.new(
        key: :cross_references,
        label: "Cross-references",
        count: 1,
        examples: [
          WeeklyDigestCollector::Example.new(
            title: "John 3:16 → Romans 5:8",
            url: "http://localhost:3000/bible_verses/John/3/16",
            detail: "These verses both speak of God's love demonstrated in Christ."
          )
        ],
        contribute_path: "http://localhost:3000/bible_verses/books"
      ),
      WeeklyDigestCollector::Section.new(
        key: :topics,
        label: "Topics",
        count: 0,
        examples: [],
        contribute_path: "http://localhost:3000/topics"
      ),
      WeeklyDigestCollector::Section.new(
        key: :bible_threads,
        label: "Bible Threads",
        count: 0,
        examples: [],
        contribute_path: "http://localhost:3000/bible_threads/new"
      ),
      WeeklyDigestCollector::Section.new(
        key: :chiasms,
        label: "Chiasms",
        count: 0,
        examples: [],
        contribute_path: "http://localhost:3000/chiasms/new"
      )
    ]

    WeeklyDigestMailer.digest(
      user,
      summary: summary,
      week_start: range.begin,
      week_end: range.end
    )
  end
end
