# frozen_string_literal: true

module Billing
  class PlanPresenter
    def initialize(plan)
      @plan = plan
    end

    def as_json(_options = {})
      return {} unless plan

      plan.attributes.symbolize_keys.merge({
                                             id: plan.id
                                           })
    end

    private

    attr_reader :plan
  end
end
