# frozen_string_literal: true

module Billing
  class PlanFeature < ApplicationRecord
    self.table_name = 'billing_plan_features'

    belongs_to :plan, class_name: 'Billing::Plan'
    belongs_to :feature, class_name: 'Billing::Feature'

    validates :feature_id, uniqueness: { scope: :plan_id }
  end
end
