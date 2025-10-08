class Api::V1::Accounts::Billing::ResellerSubscriptionsController < Api::V1::Accounts::Billing::BaseController
  before_action :check_admin_authorization?

  def create
    result = Billing::Asaas::SubscriptionService.new(
      account: Current.account,
      plan_code: subscription_params[:plan_code],
      customer_attributes: subscription_params[:customer],
      payment_method: subscription_params[:payment_method],
      seats: subscription_params[:seats],
      addons: subscription_params[:addons]
    ).call

    render json: {
      subscription: result[:subscription],
      customer: result[:customer],
      plan: Billing::AccountPlanPresenter.new(result[:account_plan]).as_json
    }, status: :created
  end

  private

  def subscription_params
    permitted = params.require(:reseller_subscription).permit(:plan_code, :payment_method, :seats, addons: {})
    permitted[:addons] = permitted[:addons].to_h if permitted[:addons].respond_to?(:to_h)
    customer_attributes = params[:reseller_subscription][:customer]
    permitted[:customer] = if customer_attributes.respond_to?(:permit!)
                             customer_attributes.permit!.to_h
                           else
                             customer_attributes || {}
                           end
    permitted
  end
end
