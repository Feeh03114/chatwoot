# frozen_string_literal: true

module Billing
  class WebhookRecorder
    def initialize(provider:, event_id:, event_type:, payload: {})
      @provider = provider
      @event_id = event_id
      @event_type = event_type
      @payload = payload
    end

    def processed?
      Billing::WebhookEvent.exists?(provider: provider, event_id: event_id)
    end

    def record!
      Billing::WebhookEvent.create!(
        provider: provider,
        event_type: event_type,
        event_id: event_id,
        payload: payload,
        processed_at: Time.zone.now
      )
    end

    private

    attr_reader :provider, :event_id, :event_type, :payload
  end
end
