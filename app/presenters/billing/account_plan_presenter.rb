# frozen_string_literal: true

module Billing
  class AccountPlanPresenter
    def initialize(account_plan)
      @account_plan = account_plan
    end

    def as_json(_options = {})
      return {} unless account_plan

      {
        plan: Billing::PlanPresenter.new(account_plan.plan).as_json,
        status: account_plan.status,
        seats: {
          allocated: account_plan.seats_allocated,
          used: account_plan.seats_used
        },
        current_period_end: account_plan.current_period_end,
        provider: account_plan.provider,
        metadata: account_plan.metadata
      }
    end

    private

    attr_reader :account_plan
  end
end
