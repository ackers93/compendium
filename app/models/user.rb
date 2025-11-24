class User < ApplicationRecord
    has_many :notes, dependent: :destroy
    has_many :comments, dependent: :destroy
    has_many :cross_references, dependent: :destroy
    has_many :bible_threads, dependent: :destroy
    
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
           
    validates :email, presence: true, uniqueness: true
    
    # Roles enum
    enum :role, { viewer: 'viewer', contributor: 'contributor', admin: 'admin' }, prefix: true
    
    # Set default role after initialization
    after_initialize :set_default_role, if: :new_record?
    
    # Send notification to head admin when new user signs up
    after_create :notify_admin_of_signup
    
    # OTP/2FA Configuration
    OTP_EXPIRY_TIME = 10.minutes
    
    # Generate a 6-digit OTP code
    def generate_otp
      self.otp_secret = rand(100000..999999).to_s
      self.otp_sent_at = Time.current
      save!
    end
    
    # Verify the OTP code
    def verify_otp(code)
      return false if otp_secret.blank? || otp_sent_at.blank?
      return false if Time.current > otp_sent_at + OTP_EXPIRY_TIME
      
      otp_secret == code.to_s
    end
    
    # Clear OTP after successful verification
    def clear_otp
      update(otp_secret: nil, otp_sent_at: nil)
    end
    
    # Check if OTP is required for this user
    def otp_required?
      otp_required_for_login
    end
    
    # Authorization methods
    def can_view?(resource = nil)
      true # All users can view
    end
    
    def can_create?
      role_contributor? || role_admin?
    end
    
    def can_edit?(resource)
      return true if role_admin?
      return false unless role_contributor?
      
      # Contributors can only edit their own content
      resource.respond_to?(:user_id) && resource.user_id == id
    end
    
    def can_update?(resource)
      can_edit?(resource)
    end
    
    def can_delete?(resource)
      can_edit?(resource)
    end
    
    def can_manage_users?
      role_admin?
    end
    
    # Onboarding methods
    def needs_user_onboarding?
      onboarding_completed_at.nil?
    end
    
    def needs_admin_onboarding?
      role_admin? && admin_onboarding_completed_at.nil?
    end
    
    def needs_any_onboarding?
      needs_user_onboarding? || needs_admin_onboarding?
    end
    
    def complete_user_onboarding!
      update(onboarding_completed_at: Time.current)
    end
    
    def complete_admin_onboarding!
      update(admin_onboarding_completed_at: Time.current)
    end
    
    # Get count of flagged content needing review for this user
    def flagged_content_needing_review_count
      note_ids = notes.pluck(:id)
      comment_ids = comments.pluck(:id)
      cross_ref_ids = cross_references.pluck(:id)
      thread_ids = bible_threads.pluck(:id)
      
      # Return 0 if user has no content
      return 0 if note_ids.empty? && comment_ids.empty? && cross_ref_ids.empty? && thread_ids.empty?
      
      conditions = []
      params = []
      
      unless note_ids.empty?
        conditions << '(flaggable_type = ? AND flaggable_id IN (?))'
        params += ['Note', note_ids]
      end
      
      unless comment_ids.empty?
        conditions << '(flaggable_type = ? AND flaggable_id IN (?))'
        params += ['Comment', comment_ids]
      end
      
      unless cross_ref_ids.empty?
        conditions << '(flaggable_type = ? AND flaggable_id IN (?))'
        params += ['CrossReference', cross_ref_ids]
      end
      
      unless thread_ids.empty?
        conditions << '(flaggable_type = ? AND flaggable_id IN (?))'
        params += ['BibleThread', thread_ids]
      end
      
      ContentFlag.where(conditions.join(' OR '), *params)
                 .status_review_requested
                 .count
    end
    
    # Display name in format "name - ecclesia"
    def display_name
      if name.present? && ecclesia.present?
        "#{name} - #{ecclesia}"
      elsif name.present?
        name
      elsif ecclesia.present?
        ecclesia
      else
        email || "Unknown User"
      end
    end
    
    private
    
    def set_default_role
      self.role ||= 'viewer'
    end
    
    def notify_admin_of_signup
      AdminNotificationMailer.new_user_signup(self).deliver_later
    end
    
    # Defensive methods to prevent serialization issues
    def empty?
      false
    end
    
    def to_s
      email || "User"
    end
end