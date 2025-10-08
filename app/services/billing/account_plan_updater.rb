# frozen_string_literal: true

module Billing
  class AccountPlanUpdater
    def initialize(account_id:, plan_code:, provider:, seats: nil, status: 'active', current_period_end: nil,
                   provider_customer_id: nil, provider_subscription_id: nil, metadata: {})
      @account_id = account_id
      @plan_code = plan_code
      @provider = provider
      @seats = seats
      @status = status
      @current_period_end = current_period_end
      @provider_customer_id = provider_customer_id
      @provider_subscription_id = provider_subscription_id
      @metadata = metadata
    end

    def call
      account_plan = find_or_initialize_account_plan
      account_plan.plan = plan
      account_plan.status = status
      account_plan.seats_allocated = seats || plan.agents_included
      account_plan.current_period_end = current_period_end
      account_plan.provider_customer_id = provider_customer_id if provider_customer_id.present?
      account_plan.provider_subscription_id = provider_subscription_id if provider_subscription_id.present?
      account_plan.metadata = (account_plan.metadata || {}).merge(metadata)

      account_plan.save!

      Billing::AccountSeatManager.new(account_plan).sync!
      account_plan
    end

    private

    attr_reader :account_id, :plan_code, :provider, :seats, :status, :current_period_end,
                :provider_customer_id, :provider_subscription_id, :metadata

    def plan
      @plan ||= Billing::Plan.find_by!(code: plan_code)
    end

    def account
      @account ||= Account.find(account_id)
    end

    def find_or_initialize_account_plan
      account.billing_account_plans.find_or_initialize_by(provider: provider)
    end
  end
end
