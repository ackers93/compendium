# Content Flagging System Documentation

## Overview
The application now includes a comprehensive content flagging system that allows users to flag inappropriate, incorrect, or problematic content for admin review. This system helps maintain content quality and community standards.

## Features

### For All Users
Users can flag any of the following content types:
- **Notes**: Full articles and study notes
- **Comments**: Comments on notes, Bible verses, or cross-references
- **Cross-References**: Biblical cross-reference connections

#### How to Flag Content
1. Navigate to any note, comment, or cross-reference
2. Look for the "Flag for Review" button or link (displayed next to content actions)
3. Click the flag button and enter a reason for flagging
4. The content will be immediately flagged and sent to admins for review

**Note**: Users cannot flag content they can edit/delete (their own content or if they're admin).

### For Contributors & Content Authors

#### Viewing Your Flagged Content
- URL: `/my-flagged-content`
- Accessible via "My Content" in the main navigation
- A notification badge shows the number of items needing your review
- View all flags on your content across all types (notes, comments, cross-references)

#### What You'll See
When admins request a review on your content, you'll see:
- **Content Details**: Which of your content was flagged
- **Reason**: Why it was flagged by the user
- **Admin Feedback**: Specific guidance from the admin on what needs to be changed
- **Status**: Current status (pending, review requested, approved, edited, deleted)
- **Action Buttons**: Quick access to edit or view the flagged content

#### Status Filters
- **Review Requested**: Content that needs your attention (default view)
- **Under Review**: Content flagged but not yet reviewed by admins
- **Approved**: Content that was flagged but deemed acceptable
- **Edited**: Content that has been revised
- **Deleted**: Content that was removed

### For Admins

#### Accessing Flagged Content
- URL: `/admin/content_flags`
- Accessible via the Admin navigation in the top menu
- A notification badge shows the number of pending flags

#### Admin Dashboard Features

##### 1. Status Overview Cards
View statistics for all flag statuses:
- **Pending Review**: Flags awaiting admin action
- **Approved**: Content approved despite being flagged
- **Review Requested**: Admin requested author to review/revise
- **Edited**: Content was edited by admin or author
- **Deleted**: Content was removed

##### 2. Status Filter Tabs
- Filter flags by status (Pending, Approved, Review Requested, Edited, Deleted)
- Default view shows pending flags requiring action

##### 3. Flag Details
Each flag displays:
- Content type (Note, Comment, or Cross-Reference)
- Content title/preview
- Flagged by (user who flagged it)
- Content author
- Reason for flagging
- Preview of the flagged content
- Timestamp of when it was flagged

##### 4. Admin Actions (for Pending Flags)

**Approve**
- Marks the content as reviewed and acceptable
- Content remains published
- Flag status changes to "approved"

**Request Review**
- Notifies content author via their "My Content" page
- Optional: Add a note for the author explaining what needs to be changed
- Flag status changes to "review_requested"
- Badge notification appears in author's navigation
- *Future enhancement: Email notification to author*

**Edit Content**
- Redirects admin to the content edit page
- Admin can directly fix issues with the content
- After editing, flag can be marked as resolved

**Delete Content**
- Permanently removes the flagged content
- Optional: Add a note explaining why
- Requires confirmation
- Flag status changes to "deleted"

**View Content**
- Opens the content in a new tab for full review
- Allows admin to see the content in context

## Implementation Details

### Database Schema

#### ContentFlags Table
```ruby
create_table :content_flags do |t|
  t.references :flaggable, polymorphic: true, null: false  # The flagged content
  t.references :user, null: false, foreign_key: true       # User who flagged
  t.text :reason                                            # Why it was flagged
  t.string :status, default: 'pending', null: false        # Flag status
  t.references :resolved_by, foreign_key: { to_table: :users }  # Admin who resolved
  t.datetime :resolved_at                                   # When it was resolved
  t.text :admin_note                                        # Admin's note/explanation
  t.timestamps
end
```

**Indexes:**
- `status` - for filtering by status
- `[flaggable_type, flaggable_id]` - for finding flags for specific content

### Models

#### ContentFlag Model
- **Belongs to**: `flaggable` (polymorphic), `user`, `resolved_by`
- **Enum**: `status` (pending, approved, review_requested, edited, deleted)
- **Validations**: Presence of user, flaggable, and status
- **Scopes**: 
  - `pending` - only pending flags
  - `resolved` - all resolved flags
  - `recent` - ordered by creation date (newest first)

#### Updated Models
All flaggable models now include:
```ruby
has_many :content_flags, as: :flaggable, dependent: :destroy
```
- **Note**
- **Comment**
- **CrossReference**

### Controllers

#### ContentFlagsController
- **Action**: `create`
- **Purpose**: Handles flag submissions from users
- **Validation**: 
  - Prevents duplicate flags (same user + same content + pending status)
  - Requires reason for flagging
- **Authorization**: Requires authenticated user

#### Admin::ContentFlagsController
- **Actions**: `index`, `approve`, `request_review`, `edit_content`, `destroy_content`
- **Authorization**: Admin only (via `authorize_admin!`)
- **Features**:
  - Lists all flags with filtering
  - Provides all resolution actions
  - Tracks who resolved each flag and when

### Routes

```ruby
# User-facing flag creation
POST /content_flags

# Contributor's flagged content dashboard
GET  /my-flagged-content                       # View your flagged content

# Admin flag management
GET    /admin/content_flags                    # List all flags
PATCH  /admin/content_flags/:id/approve        # Approve flagged content
PATCH  /admin/content_flags/:id/request_review # Request author review
GET    /admin/content_flags/:id/edit_content   # Redirect to edit page
DELETE /admin/content_flags/:id/destroy_content # Delete flagged content
```

### Views

#### User-Facing Flag Buttons
Flag functionality is added to:
- **Notes**: Flag button appears for users who cannot edit the note
- **Comments**: "Flag" link in comment header for users who cannot edit
- **Cross-References**: "Flag" link in actions column for users who cannot delete

#### Admin Interface
- **Navigation**: Shared admin navigation with User Management and Flagged Content tabs
- **Index Page**: Comprehensive flag listing with status cards, filters, and actions
- **Styling**: Consistent with existing admin design system

### JavaScript
Global `flagContent(contentType, contentId)` function:
- Prompts user for flag reason
- Creates and submits a form with CSRF token
- Handles all three content types (Note, Comment, CrossReference)
- Located in application layout for global access

### Styling
Flag-specific styles in `app/assets/stylesheets/components/_admin.scss`:
- `.flag-card` - Individual flag container
- `.flag-header`, `.flag-content`, `.flag-actions` - Flag sections
- `.flag-meta` - Metadata grid
- `.flag-reason` - Highlighted reason display
- Badge status colors for all flag statuses
- Responsive stat cards for the admin dashboard

## Security & Permissions

### User Permissions
- All authenticated users can flag content
- Users cannot flag their own content
- Admins can flag content but primarily use direct edit/delete

### Admin Permissions
- Only users with `role_admin?` can access admin flag management
- All flag resolution actions require admin authentication
- Authorization checked via `Authorizable` concern

## Future Enhancements

### Planned Features
1. **Email Notifications**
   - Notify content authors when their content is flagged
   - Alert authors when review is requested
   - Confirm to flaggers when action is taken

2. **Flag Analytics**
   - Track which users frequently flag content
   - Identify content that receives multiple flags
   - Generate reports on flag resolution times

3. **Auto-Moderation**
   - Automatic actions based on flag count
   - Hide content with multiple pending flags
   - Pattern detection for problematic content

4. **Enhanced Workflow**
   - Assign flags to specific admin reviewers
   - Flag priority levels (low, medium, high, urgent)
   - Bulk flag actions for efficient moderation

5. **User Flag History**
   - View all flags submitted by a user
   - Track flag accuracy (approved vs. rejected)
   - Prevent flag abuse

## Usage Examples

### Example 1: User Flags Inappropriate Comment
1. User sees inappropriate language in a comment
2. Clicks "Flag" link next to the comment
3. Enters reason: "Contains offensive language"
4. Admin receives notification
5. Admin reviews content and deletes comment
6. Flag marked as "deleted" with admin note

### Example 2: Admin Requests Review (Complete Workflow)
1. User flags a note for factual inaccuracy
2. Admin reviews and identifies the issue
3. Admin clicks "Request Review"
4. Adds note: "Please verify the dates mentioned in paragraph 3"
5. Flag status changes to "review_requested"
6. Author sees notification badge (🔔 1) in "My Content" navigation
7. Author visits "My Content" page and sees:
   - The flag reason
   - The admin's specific feedback
   - "Edit Content" button
8. Author clicks "Edit Content" and makes revisions
9. **Upon saving**, the system automatically:
   - Changes flag status back to "pending" for admin re-review
   - Adds update timestamp to the flag
   - Shows success message: "Content updated and submitted back to admins for review"
   - Removes the notification badge for the author
10. Admin sees the flag back in "Pending" view with:
    - Green "Content has been updated by the author and is ready for re-review!" notice
    - Updated timestamp showing when author made changes
    - Original admin note plus update history
11. Admin reviews the updated content and can then:
    - Approve it (content was fixed)
    - Request another review (needs more work)
    - Delete it (still problematic)

### Example 3: Admin Approves Content
1. User flags a controversial but valid theological perspective
2. Admin reviews and determines content is appropriate
3. Admin clicks "Approve"
4. Content remains published
5. Flag marked as "approved"
6. Creates record of administrative review

## Testing

### Manual Testing Checklist

**User Flagging:**
- [ ] User can flag a note they didn't create
- [ ] User can flag a comment they didn't create
- [ ] User can flag a cross-reference they didn't create
- [ ] User cannot flag their own content
- [ ] User cannot flag same content twice while pending

**Contributor Dashboard:**
- [ ] Contributors can access "My Content" page
- [ ] Badge shows count of review-requested items
- [ ] Can see all flags on their content
- [ ] Can filter by status
- [ ] Can edit flagged content from the page
- [ ] Admin notes/feedback are visible
- [ ] Can view deleted content details (even if content is gone)

**Admin Actions:**
- [ ] Admin can see all pending flags
- [ ] Admin can filter flags by status
- [ ] Admin can approve a flag
- [ ] Admin can request review with note
- [ ] Admin can edit flagged content
- [ ] Admin can delete flagged content with confirmation
- [ ] Flag counts display correctly in admin nav
- [ ] Flag status changes are tracked correctly

## Troubleshooting

### Common Issues

**Issue**: Flag button not appearing
- **Check**: User must be authenticated
- **Check**: User must not be able to edit/delete the content
- **Solution**: Verify user permissions and content ownership

**Issue**: Admin actions not working
- **Check**: User has admin role
- **Check**: CSRF token is present in form
- **Solution**: Verify admin authentication and Rails CSRF protection

**Issue**: Flagging returns "already flagged" error
- **Check**: User has pending flag for this content
- **Solution**: Resolve existing flag before allowing new flag

## Database Queries

### Useful Queries for Analytics

```ruby
# Total flags by status
ContentFlag.group(:status).count

# Most flagged content
ContentFlag.group(:flaggable_type).count

# Flags resolved by each admin
ContentFlag.where.not(resolved_by: nil).group(:resolved_by_id).count

# Average time to resolution
ContentFlag.where.not(resolved_at: nil)
  .average("EXTRACT(EPOCH FROM (resolved_at - created_at))")

# Flags for a specific user's content
ContentFlag.joins("INNER JOIN notes ON notes.id = content_flags.flaggable_id AND content_flags.flaggable_type = 'Note'")
  .where(notes: { user_id: user_id })
```

## Maintenance

### Regular Tasks
1. **Weekly**: Review resolved flags for patterns
2. **Monthly**: Archive old resolved flags (optional)
3. **Quarterly**: Analyze flag trends and user behavior
4. **As Needed**: Update flag categories and reasons

### Performance Considerations
- Indexes on `status` and `flaggable` optimize queries
- Scopes use database-level filtering
- Eager loading used for admin interface (`includes(:user, :flaggable, :resolved_by)`)

## Support

For questions or issues with the flagging system:
1. Check this documentation
2. Review the code comments in models and controllers
3. Check Rails logs for error messages
4. Test in development environment first

---

**Version**: 1.0  
**Last Updated**: November 13, 2025  
**Author**: AI Assistant  
**Status**: Implemented and Ready for Production

