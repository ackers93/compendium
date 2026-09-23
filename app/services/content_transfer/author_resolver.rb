# frozen_string_literal: true

module ContentTransfer
  class AuthorResolver
    def initialize(admin:)
      @admin = admin
      @cache = {}
      @missing = []
    end

    def resolve(email)
      key = email.to_s.strip.downcase
      return [@admin, false] if key.blank?
      return @cache[key] if @cache.key?(key)

      user = User.find_by("LOWER(email) = ?", key)
      if user
        @cache[key] = [user, false]
      else
        @missing << key unless @missing.include?(key)
        @cache[key] = [@admin, true]
      end
    end

    def missing_emails
      @missing.dup
    end
  end
end
