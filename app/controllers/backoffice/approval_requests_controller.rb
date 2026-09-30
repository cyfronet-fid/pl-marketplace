# frozen_string_literal: true

class Backoffice::ApprovalRequestsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show update]

  def index
    @approval_requests = ApprovalRequest.active.order(created_at: :desc)
  end

  def edit
  end

  def show
  end

  def update
    result = ApprovalRequest::Review.call(@approval_request, reviewer: current_user, **review_params)

    @approval_requests = ApprovalRequest.active.order(created_at: :desc)
    @message = result.message

    respond_to { |format| result.success? ? respond_with_success(format) : respond_with_error(format) }
  end

  private

  def find_and_authorize
    @approval_request = authorize(ApprovalRequest.includes(:messages).find(params[:id]))
  end

  def review_params
    attributes = permitted_attributes(ApprovalRequest)
    { action: attributes["current_action"], text: attributes["message"] }
  end

  def respond_with_success(format)
    flash.now[:notice] = _("Message sent successfully")
    format.turbo_stream { render :update, status: :ok }
    format.html { redirect_to backoffice_providers_path }
  end

  def respond_with_error(format)
    flash.now[:alert] = _("Message not sent")
    format.turbo_stream { render :update, status: :unprocessable_entity }
    format.html { render :show, status: :unprocessable_entity }
    format.json { render :edit, status: :unprocessable_entity }
  end
end
