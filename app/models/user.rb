class User < ApplicationRecord
    has_many :notes, dependent: :destroy
    has_many :comments, dependent: :destroy
    
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
           
    validates :email, presence: true, uniqueness: true
    
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
    
    # Defensive methods to prevent serialization issues
    def empty?
      false
    end
    
    def to_s
      email || "User"
    end
end