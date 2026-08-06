module NotesHelper
  def note_tag_badge(tag)
    link_to tag, notes_path(tag: tag),
            class: "badge badge-primary",
            data: { turbo_frame: "_top" }
  end
end
