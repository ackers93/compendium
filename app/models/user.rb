class User < ApplicationRecord
    has_many :notes, dependent: :destroy
    has_many :comments, dependent: :destroy
    
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
           
    validates :email, presence: true, uniqueness: true
    
    # Defensive methods to prevent serialization issues
    def empty?
      false
    end
    
    def to_s
      email || "User"
    end
end