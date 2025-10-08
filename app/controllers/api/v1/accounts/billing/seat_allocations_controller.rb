class Api::V1::Accounts::Billing::SeatAllocationsController < Api::V1::Accounts::Billing::BaseController
  before_action :check_admin_authorization?

  def create
    account_plan = find_account_plan
    raise ActiveRecord::RecordNotFound unless account_plan

    account_plan.update!(seats_allocated: sanitized_seat_count)
    Billing::AccountSeatManager.new(account_plan).sync!

    render json: Billing::AccountPlanPresenter.new(account_plan.reload).as_json
  end

  private

  def find_account_plan
    provider = seat_params[:provider]
    scope = Current.account.billing_account_plans
    scope = scope.where(provider: provider) if provider.present?
    scope.ordered.first
  end

  def seat_params
    params.require(:seat_allocation).permit(:seats, :provider)
  end

  def sanitized_seat_count
    seats = seat_params[:seats].to_i
    seats.positive? ? seats : 1
  end
end
