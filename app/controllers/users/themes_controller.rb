# frozen_string_literal: true

class Users::ThemesController < ApplicationController
  before_action :authenticate_user!

  def update
    if current_user.update_theme_preferences(theme_params)
      redirect_to edit_user_registration_path, notice: "Style preferences saved."
    else
      redirect_to edit_user_registration_path,
                  alert: current_user.errors.full_messages.to_sentence.presence || "Could not save style preferences."
    end
  end

  def destroy
    current_user.reset_theme_preferences!
    redirect_to edit_user_registration_path, notice: "Style reset to defaults."
  end

  private

  def theme_params
    params.fetch(:theme, {}).permit(*Themeable::THEME_KEYS)
  end
end
