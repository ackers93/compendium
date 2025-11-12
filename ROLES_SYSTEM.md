# Roles System Documentation

## Overview
This application now has a comprehensive roles-based authorization system with three levels of access: Viewer, Contributor, and Admin.

## Role Types

### Viewer (Default)
- **Permissions**: Can only view content
- **Default Role**: All new users are created as viewers
- **Access**: Read-only access to notes, Bible verses, comments, and cross-references

### Contributor
- **Permissions**: Can create, read, edit, and delete their own content
- **Access**:
  - Create new notes
  - Edit/delete their own notes
  - Add comments on any content
  - Edit/delete their own comments
  - Add cross-references
  - Edit/delete their own cross-references

### Admin
- **Permissions**: Full access to all content and user management
- **Access**:
  - All Contributor permissions
  - Edit/delete ANY user's content
  - Access to Admin Dashboard
  - Manage user roles (promote/demote users)
  - Delete users

## Admin Dashboard

### Access
- URL: `/admin/users`
- Only accessible to users with Admin role
- Link appears in navigation bar for admins

### Features
1. **User Statistics**
   - View counts of Viewers, Contributors, and Admins
   - Quick filter links to view users by role

2. **User Management Table**
   - View all users with email, name, role, and creation date
   - Edit user roles
   - Delete spam users
   - Current user is highlighted

3. **Role Management**
   - Change any user's role between Viewer, Contributor, and Admin
   - Visual role badges with color coding:
     - Viewer: Blue
     - Contributor: Green
     - Admin: Purple

## Implementation Details

### User Model
- `app/models/user.rb`
- Includes role enum with three values
- Authorization methods:
  - `can_view?(resource)` - Always true for all users
  - `can_create?` - True for Contributors and Admins
  - `can_edit?(resource)` - True for resource owner (Contributors) or Admins
  - `can_delete?(resource)` - Same as can_edit?
  - `can_manage_users?` - True only for Admins

### Authorizable Concern
- `app/controllers/concerns/authorizable.rb`
- Provides controller methods:
  - `authorize_create!`
  - `authorize_edit!(resource)`
  - `authorize_delete!(resource)`
  - `authorize_admin!`
- Handles unauthorized access with flash messages and redirects

### Controllers with Authorization
- `NotesController`
- `CommentsController`
- `CrossReferencesController`
- `Admin::UsersController`

### Views with Conditional UI
All creation, edit, and delete buttons are conditionally shown based on user permissions:
- Notes index (new note button)
- Note show (edit/delete buttons)
- Comments (edit/delete links)
- Bible verses (add comment/cross-reference buttons)

### Navigation
- Role badge displayed next to user email in navbar
- Admin link only visible to admins
- Color-coded role indicators throughout the app

## Database Schema

### Users Table
- `role` column (string) stores: 'viewer', 'contributor', or 'admin'
- Default value set to 'viewer' on user creation

### Cross References Table
- Added `user_id` column to track who created each cross-reference
- Enables contributors to only edit/delete their own cross-references

## Upgrading Existing Users

To promote existing users to different roles, use the Admin Dashboard or Rails console:

```ruby
# In Rails console
user = User.find_by(email: 'user@example.com')
user.update(role: 'admin')
# or
user.update(role: 'contributor')
```

## Security Notes

1. All authorization is enforced both in views (UI) and controllers (backend)
2. Viewers attempting to access restricted actions receive appropriate error messages
3. Admin dashboard is protected by `authorize_admin!` callback
4. Users cannot delete themselves from the admin dashboard
5. All role changes are logged in the application

## Future Enhancements

Consider adding:
- Activity logging for role changes
- Email notifications when users are promoted
- Bulk role management
- Team/group management
- Custom permission sets beyond the three basic roles

