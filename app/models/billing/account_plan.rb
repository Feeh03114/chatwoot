# frozen_string_literal: true

module Billing
  class AccountPlan < ApplicationRecord
    self.table_name = 'billing_account_plans'

    enum status: { active: 'active', past_due: 'past_due', canceled: 'canceled' }

    belongs_to :account
    belongs_to :plan, class_name: 'Billing::Plan'

    validates :provider, presence: true
    validates :plan, presence: true
    validates :account, presence: true
    validates :seats_allocated, numericality: { greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: statuses.keys }

    scope :ordered, -> { order(updated_at: :desc) }

    def limits
      plan.limits_hash
    end

    def feature_keys
      plan.feature_keys
    end
  end
end
