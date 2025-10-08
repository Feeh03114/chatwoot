# frozen_string_literal: true

module Billing
  class Feature < ApplicationRecord
    self.table_name = 'billing_features'

    has_many :plan_features, class_name: 'Billing::PlanFeature', dependent: :destroy
    has_many :plans, through: :plan_features

    validates :key, presence: true, uniqueness: true
  end
end
