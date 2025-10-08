class Api::V1::Accounts::Billing::CheckoutSessionsController < Api::V1::Accounts::Billing::BaseController
  before_action :check_admin_authorization?

  def create
    plan = Billing::Plan.published.find_by!(code: checkout_params[:plan_code], provider: 'stripe')

    session = Billing::Stripe::CheckoutSessionService.new(
      account: Current.account,
      plan: plan,
      success_url: checkout_params[:success_url].presence || default_return_url,
      cancel_url: checkout_params[:cancel_url].presence || default_return_url,
      quantity: checkout_params[:quantity],
      metadata: (checkout_params[:metadata] || {}).to_h
    ).call

    render json: { checkout_url: session.url }
  end

  private

  def checkout_params
    params.require(:checkout_session).permit(:plan_code, :success_url, :cancel_url, :quantity, metadata: {})
  end

  def default_return_url
    base = ENV.fetch('FRONTEND_URL', nil)
    base = request.base_url if base.blank?
    "#{base}/app/accounts/#{Current.account.id}/settings/billing"
  rescue StandardError
    request.base_url
  end
end
