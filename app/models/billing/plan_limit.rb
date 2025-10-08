# frozen_string_literal: true

module Billing
  class PlanLimit < ApplicationRecord
    self.table_name = 'billing_plan_limits'

    belongs_to :plan, class_name: 'Billing::Plan'

    validates :limit_key, presence: true, uniqueness: { scope: :plan_id }
    validates :limit_value, numericality: { greater_than_or_equal_to: 0 }
  end
end
