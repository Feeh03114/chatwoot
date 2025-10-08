# frozen_string_literal: true

module Billing
  class Plan < ApplicationRecord
    self.table_name = 'billing_plans'

    PROVIDERS = %w[stripe asaas].freeze

    has_many :plan_features, class_name: 'Billing::PlanFeature', dependent: :destroy
    has_many :features, through: :plan_features
    has_many :plan_limits, class_name: 'Billing::PlanLimit', dependent: :destroy
    has_many :account_plans, class_name: 'Billing::AccountPlan', dependent: :destroy

    scope :published, -> { where(public: true) }

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :billing_cycle, presence: true
    validates :provider, presence: true, inclusion: { in: PROVIDERS }
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :agents_included, numericality: { greater_than_or_equal_to: 0 }
    validates :extra_agent_price_cents, numericality: { greater_than_or_equal_to: 0 }

    def feature_keys
      @feature_keys ||= features.order(:key).pluck(:key)
    end

    def limits_hash
      plan_limits.each_with_object({}) do |limit, memo|
        memo[limit.limit_key] = limit.limit_value
      end
    end

    def to_h
      {
        code: code,
        name: name,
        price_cents: price_cents,
        currency: currency,
        billing_cycle: billing_cycle,
        provider: provider,
        provider_price_id: provider_price_id,
        agents_included: agents_included,
        extra_agent_price_cents: extra_agent_price_cents,
        features: feature_keys,
        limits: limits_hash,
        public: public,
        metadata: metadata
      }
    end
  end
end
