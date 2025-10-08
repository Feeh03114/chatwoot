class Api::V1::Accounts::Billing::PlansController < Api::V1::Accounts::Billing::BaseController
  before_action :check_admin_authorization?

  def show
    account_plan = Current.account.billing_account_plans.ordered.first
    render json: {
      plan: Billing::AccountPlanPresenter.new(account_plan).as_json,
      plans: Billing::Plan.published.order(price_cents: :asc).map { |plan| Billing::PlanPresenter.new(plan).as_json },
      limits: Current.account.usage_limits,
      features: Current.account.billing_feature_keys
    }
  end
end
