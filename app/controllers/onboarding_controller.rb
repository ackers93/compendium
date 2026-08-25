class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_onboarding_needed

  def show
    @onboarding_type = determine_onboarding_type
    @steps = user_onboarding_steps if @onboarding_type == "user"
  end

  def complete
    case params[:type]
    when "user"
      accepted_agreement = ActiveModel::Type::Boolean.new.cast(params[:accept_contributor_agreement])

      if accepted_agreement
        current_user.accept_contributor_agreement!
        flash[:notice] = "Welcome to Compendium! You've accepted the Contributor Agreement—an admin can now promote you when ready."
      else
        flash[:notice] = "Welcome to Compendium! You're signed in as a Viewer. Accept the Contributor Agreement anytime from your Profile to request Contributor access."
      end

      current_user.complete_user_onboarding!
      redirect_to root_path
    when "admin"
      current_user.complete_admin_onboarding!
      flash[:notice] = "Admin features unlocked! You now have full access to user management."
      redirect_to admin_users_path
    else
      redirect_to root_path
    end
  end

  def skip
    case params[:type]
    when "user"
      current_user.complete_user_onboarding!
      flash[:notice] = "Welcome to Compendium! You're signed in as a Viewer. Accept the Contributor Agreement anytime from your Profile to request Contributor access."
    when "admin"
      current_user.complete_admin_onboarding!
    end
    redirect_to root_path
  end

  private

  def check_onboarding_needed
    unless current_user.needs_any_onboarding?
      redirect_to root_path
    end
  end

  def determine_onboarding_type
    # Admin onboarding takes priority if both are needed
    if current_user.needs_admin_onboarding?
      "admin"
    elsif current_user.needs_user_onboarding?
      "user"
    end
  end

  def user_onboarding_steps
    can_create = current_user.can_create?

    [
      {
        key: "welcome",
        icon: "fa-book-open",
        title: "Welcome to Compendium",
        body: "Your Bible study companion for reading Scripture, capturing insights, and exploring connections with others. This short tour walks through each part of the app.",
        screenshot: nil
      },
      {
        key: "notes",
        icon: "fa-note-sticky",
        title: "Notes",
        body: can_create ?
          "Create study notes, save sermon insights, and organize your thoughts. Keep drafts private while you work, then publish when you're ready to share with the community." :
          "Browse and read notes from contributors. Accept the Contributor Agreement at the end of this tour (or later in Profile) so an admin can promote you to write your own.",
        screenshot: "onboarding/notes.png"
      },
      {
        key: "comments",
        icon: "fa-comments",
        title: "Bible Verse Comments",
        body: can_create ?
          "Open any verse and add comments to share insights, ask questions, or discuss interpretation with others studying the same passage." :
          "Read comments others have left on verses. Contributor access lets you add your own.",
        screenshot: "onboarding/comments.png"
      },
      {
        key: "cross_references",
        icon: "fa-link",
        title: "Cross-References",
        body: can_create ?
          "Connect related verses to build a web of scriptural relationships. Cross-references help you move from one passage to another as you study." :
          "View cross-references created by contributors to discover related passages from any verse.",
        screenshot: "onboarding/cross_references.png"
      },
      {
        key: "topics",
        icon: "fa-tags",
        title: "Topics",
        body: can_create ?
          "Browse themes like salvation, prayer, and faith. Create new topics and search existing ones to find verses organized by subject." :
          "Browse topics to find verses organized by theme. Topics gather related Scripture in one place.",
        screenshot: "onboarding/topics1.png"
      },
      {
        key: "topic_detail",
        icon: "fa-tag",
        title: "Inside a Topic",
        body: can_create ?
          "Open a topic to see every associated verse with an optional explanation of how it connects. Add verses, edit explanations, or remove ones that no longer fit." :
          "Open a topic to read the verses gathered under that theme, along with explanations of how each verse connects.",
        screenshot: "onboarding/topics2.png"
      },
      {
        key: "threads",
        icon: "fa-list-ol",
        title: "Threads",
        body: can_create ?
          "Browse ordered verse collections that follow a doctrine or theme. Search existing threads, create a new one, or add verses to a thread someone else started." :
          "Explore Bible threads created by contributors—thematic verse sequences you can open and follow.",
        screenshot: "onboarding/threads1.png"
      },
      {
        key: "thread_detail",
        icon: "fa-book-bible",
        title: "Inside a Thread",
        body: can_create ?
          "Each thread walks through Scripture verse by verse, with optional commentary on every step. Any contributor can edit the sequence or add verses as the study grows." :
          "Open a thread to follow the verses in order, with commentary explaining each connection along the way.",
        screenshot: "onboarding/threads2.png"
      },
      {
        key: "chiasms",
        icon: "fa-arrows-left-right-to-line",
        title: "Chiasms",
        body: can_create ?
          "Select a scripture range and highlight chiastic limbs—even mid-verse. Layers indent and color so the structure is easy to read." :
          "Explore chiastic outlines created by contributors, with indented layers that reveal the passage’s mirrored structure.",
        screenshot: "onboarding/threads1.png"
      },
      {
        key: "search",
        icon: "fa-magnifying-glass",
        title: "Search",
        body: "Search across topics, notes, threads, chiasms, verses, and comments from one place. Use Search in the navigation whenever you need to find something quickly.",
        screenshot: "onboarding/search.png"
      },
      {
        key: "flagging",
        icon: "fa-flag",
        title: "Flagging content",
        body: "See something inappropriate or incorrect? Use Flag on notes, comments, cross-references, threads, or chiasms to report it. Admins review flags and can request changes or remove content. Check My Content in your profile menu for items that need your attention.",
        screenshot: "onboarding/flagging.png"
      },
      {
        key: "agreement",
        icon: "fa-file-signature",
        title: "Contributor Agreement",
        body: can_create ?
          "You're already a Contributor. Please review and confirm the agreement below. Admins are notified when you accept." :
          "To become a Contributor, read and accept the agreement below. Accepting notifies an administrator, who can then promote your account. You can also continue as a Viewer and accept later from your Profile.",
        screenshot: nil,
        agreement: true
      }
    ]
  end
end
