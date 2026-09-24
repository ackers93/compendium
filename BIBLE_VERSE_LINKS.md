# Bible Verse Reference Links

## Overview

Notes and comments auto-link Bible verse references in their rich text. On save, plain text like `John 3:16` or `John 3:16-18` becomes a clickable link to that verse, and `verse_mentions` are created so the note/comment appears on the verse page.

## How It Works

1. Write a reference in a note or comment body (e.g. `Genesis 1:1`, `gen1:1`, `Is. 40:1`, `1ki:16:31`).
2. Save — `VerseReferenceAutolinker` rewrites matching text into `<a href="/bible_verses/...">` links.
3. `MentionsVerses` indexes those links (and expands ranges) into `verse_mentions`.

Short ambiguous abbreviations (e.g. lowercase `is`) are ignored unless capitalized or written with a period (`Is 40:1`, `Is. 40:1`).

## Backfill

For existing content after deploy:

```bash
bin/rails verse_mentions:backfill
```

## Related Code

- `app/services/verse_reference_scanner.rb` — finds references in text
- `app/services/verse_reference_autolinker.rb` — rewrites HTML
- `app/models/concerns/mentions_verses.rb` — save hook + mention sync
- `app/javascript/controllers/bible_verse_picker_controller.js` — cascading book/chapter/verse selects for **topic** “add verse” forms (not Trix)

## Out of Scope

- Live auto-link while typing in Trix (links appear on save)
- Auto-linking on `VerseTopic#explanation` / `TopicItem#note`
