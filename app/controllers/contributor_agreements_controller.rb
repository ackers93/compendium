class ContributorAgreementsController < ApplicationController
  before_action :authenticate_user!

  def create
    unless ActiveModel::Type::Boolean.new.cast(params[:accept_contributor_agreement])
      redirect_to edit_user_registration_path, alert: "Please confirm that you agree to the Contributor Agreement."
      return
    end

    if current_user.accept_contributor_agreement!
      redirect_to edit_user_registration_path,
                  notice: "Thank you! You've accepted the Contributor Agreement. An administrator has been notified and can promote you to Contributor."
    else
      redirect_to edit_user_registration_path, alert: "Unable to record your agreement. Please try again."
    end
  end
end
