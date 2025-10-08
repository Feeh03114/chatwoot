# frozen_string_literal: true

module Billing
  class WebhookEvent < ApplicationRecord
    self.table_name = 'billing_webhook_events'

    validates :provider, :event_type, :event_id, :processed_at, presence: true
    validates :event_id, uniqueness: { scope: :provider }

    scope :recent, -> { order(processed_at: :desc) }
  end
end
