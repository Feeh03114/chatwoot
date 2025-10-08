# frozen_string_literal: true

require 'openssl'
require 'digest'

module Billing
  module Asaas
    class WebhookHandler
      SUPPORTED_EVENTS = %w[
        PAYMENT_RECEIVED
        PAYMENT_CONFIRMED
        PAYMENT_OVERDUE
        PAYMENT_DELETED
        SUBSCRIPTION_DELETED
        SUBSCRIPTION_CREATED
        SUBSCRIPTION_ACTIVATED
      ].freeze

      def initialize(payload:, signature:, webhook_secret: ENV.fetch('ASAAS_WEBHOOK_SECRET', nil))
        @payload = payload
        @signature = signature
        @webhook_secret = webhook_secret
      end

      def process
        verify_signature!
        data = JSON.parse(payload)
        event = (data['event'] || data['type']).to_s.upcase
        return unless SUPPORTED_EVENTS.include?(event)

        recorder = Billing::WebhookRecorder.new(
          provider: 'asaas',
          event_id: data['id'] || Digest::SHA256.hexdigest(payload),
          event_type: event,
          payload: data
        )
        return if recorder.processed?

        handle_event(event, data)
        recorder.record!
      rescue JSON::ParserError => e
        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_payload', detail: e.message)
      end

      private

      attr_reader :payload, :signature, :webhook_secret

      def handle_event(event, data)
        metadata = extract_metadata(data)
        account_id = metadata[:account_id]
        plan_code = metadata[:plan_code]
        return unless account_id && plan_code

        Billing::AccountPlanUpdater.new(
          account_id: account_id,
          plan_code: plan_code,
          provider: 'asaas',
          seats: metadata[:seats],
          status: status_for(event),
          current_period_end: parse_date(data.dig('payment', 'nextDueDate') || data.dig('subscription', 'nextDueDate')),
          provider_customer_id: metadata[:customer_id] || data.dig('customer', 'id'),
          provider_subscription_id: metadata[:subscription_id] || data.dig('subscription', 'id') || data.dig('payment', 'subscription'),
          metadata: metadata.except(:account_id, :plan_code, :seats)
        ).call
      end

      def extract_metadata(data)
        raw_metadata = data.dig('subscription', 'externalReference') ||
                       data.dig('payment', 'externalReference') ||
                       data['externalReference'] ||
                       data['metadata']
        parsed_metadata = parse_reference(raw_metadata)
        parsed_metadata.merge(
          customer_id: data.dig('payment', 'customer') || data.dig('subscription', 'customer'),
          subscription_id: data.dig('subscription', 'id') || data.dig('payment', 'subscription')
        ).with_indifferent_access
      end

      def parse_reference(value)
        return {} if value.blank?

        if value.is_a?(String)
          JSON.parse(value)
        elsif value.respond_to?(:to_h)
          value.to_h
        else
          {}
        end
      rescue JSON::ParserError
        { reference: value }
      end

      def status_for(event)
        case event
        when 'PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED', 'SUBSCRIPTION_CREATED', 'SUBSCRIPTION_ACTIVATED'
          'active'
        when 'PAYMENT_OVERDUE'
          'past_due'
        when 'PAYMENT_DELETED', 'SUBSCRIPTION_DELETED'
          'canceled'
        else
          'active'
        end
      end

      def parse_date(value)
        return if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end

      def verify_signature!
        return if webhook_secret.blank?

        expected_signature = OpenSSL::HMAC.hexdigest('sha256', webhook_secret, payload)
        provided_signature = signature.to_s

        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_signature') if provided_signature.blank?
        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_signature') if provided_signature.bytesize != expected_signature.bytesize

        return if ActiveSupport::SecurityUtils.secure_compare(expected_signature, provided_signature)

        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_signature')
      rescue ArgumentError
        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_signature')
      end
    end
  end
end
