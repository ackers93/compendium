module Flaggable
  extend ActiveSupport::Concern
  
  included do
    has_many :content_flags, as: :flaggable, dependent: :destroy
    
    # After updating content, check if there are flags waiting for review
    after_update :handle_flagged_content_update
    
    # Store whether content was updated for flagged items
    attr_accessor :flagged_content_was_updated
  end
  
  private
  
  def handle_flagged_content_update
    # Find all flags that are in "review_requested" status
    review_requested_flags = content_flags.status_review_requested
    
    return if review_requested_flags.empty?
    
    # Move them back to pending for admin re-review
    review_requested_flags.each do |flag|
      flag.update(
        status: 'pending',
        resolved_by: nil,
        resolved_at: nil,
        admin_note: "#{flag.admin_note}\n\n[UPDATE] Content was updated by author on #{Time.current.strftime('%b %d, %Y at %I:%M %p')}. Ready for re-review."
      )
    end
    
    # Set flag for controller to show success message
    self.flagged_content_was_updated = true
  end
end

