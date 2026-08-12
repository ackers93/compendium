class HomeController < ApplicationController
  def index
    @features = [
      {
        title: "Complete Bible",
        body: "Read the full King James Version chapter by chapter. Open any verse to see comments, cross-references, and topics gathered by the community.",
        image: "onboarding/bible.png",
        path: bible_verses_books_path,
        cta: "Explore the Bible"
      },
      {
        title: "Notes",
        body: "Browse study notes and sermon insights from contributors. Capture your own thoughts, keep drafts private, and publish when you're ready to share.",
        image: "onboarding/notes.png",
        path: notes_path,
        cta: "Browse Notes"
      },
      {
        title: "Verse Comments",
        body: "Open any verse and read insights from others studying the same passage. Share questions, interpretation, and encouragement in context.",
        image: "onboarding/comments.png",
        path: bible_verses_books_path,
        cta: "Open the Bible"
      },
      {
        title: "Cross-References",
        body: "Follow connections between related passages. Cross-references help you move from one verse to another as themes unfold across Scripture.",
        image: "onboarding/cross_references.png",
        path: bible_verses_books_path,
        cta: "Explore Connections"
      },
      {
        title: "Topics",
        body: "Browse themes like salvation, prayer, and faith. Open a topic to see every associated verse with an explanation of how it connects.",
        image: "onboarding/topics2.png",
        path: topics_path,
        cta: "Browse Topics"
      },
      {
        title: "Bible Threads",
        body: "Follow ordered verse collections through a doctrine or theme. Each step includes optional commentary so you can walk Scripture in sequence.",
        image: "onboarding/threads2.png",
        path: bible_threads_path,
        cta: "Browse Threads"
      },
      {
        title: "Chiasms",
        body: "Map chiastic structures across a passage. Highlight limbs that may cut mid-verse, then read the outline indented by layer.",
        image: "onboarding/threads1.png",
        path: chiasms_path,
        cta: "Browse Chiasms"
      },
      {
        title: "Search",
        body: "Find topics, notes, threads, chiasms, verses, and comments from one place. Use Search whenever you need to locate something quickly.",
        image: "onboarding/search.png",
        path: search_path,
        cta: "Search Compendium"
      }
    ]
  end
end
