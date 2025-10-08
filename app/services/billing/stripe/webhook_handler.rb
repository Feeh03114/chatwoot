# frozen_string_literal: true

module Billing
  module Stripe
    class WebhookHandler
      SUPPORTED_EVENTS = %w[
        checkout.session.completed
        invoice.paid
        invoice.payment_failed
        customer.subscription.deleted
        customer.subscription.updated
      ].freeze

      def initialize(payload:, signature:, webhook_secret: ENV.fetch('STRIPE_WEBHOOK_SECRET', nil))
        @payload = payload
        @signature = signature
        @webhook_secret = webhook_secret
      end

      def process
        event = construct_event
        return unless SUPPORTED_EVENTS.include?(event['type'])

        recorder = Billing::WebhookRecorder.new(
          provider: 'stripe',
          event_id: event['id'],
          event_type: event['type'],
          payload: event.data.respond_to?(:to_hash) ? event.data.to_hash : event.data
        )
        return if recorder.processed?

        result = handle_event(event)
        recorder.record!
        result
      end

      private

      attr_reader :payload, :signature, :webhook_secret

      def construct_event
        if webhook_secret.present?
          ::Stripe::Webhook.construct_event(payload, signature, webhook_secret)
        else
          parsed = JSON.parse(payload)
          ::Stripe::Event.construct_from(parsed)
        end
      rescue JSON::ParserError => e
        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_payload', detail: e.message)
      rescue ::Stripe::SignatureVerificationError => e
        raise CustomExceptions::Billing::ProviderError.new(error: 'invalid_signature', detail: e.message)
      end

      def handle_event(event)
        case event['type']
        when 'checkout.session.completed'
          handle_checkout_completed(event)
        when 'invoice.paid'
          handle_invoice_paid(event)
        when 'invoice.payment_failed'
          handle_invoice_failed(event, 'past_due')
        when 'customer.subscription.deleted'
          handle_subscription_event(event, 'canceled')
        when 'customer.subscription.updated'
          handle_subscription_event(event, 'active')
        end
      end

      def handle_checkout_completed(event)
        session = event.data.object
        metadata = extract_metadata(session)
        account_id = metadata_account_id(metadata)
        plan_code = metadata_plan_code(metadata)
        return unless account_id && plan_code

        Billing::AccountPlanUpdater.new(
          account_id: account_id,
          plan_code: plan_code,
          provider: 'stripe',
          seats: metadata_seats(metadata),
          status: 'active',
          current_period_end: timestamp_to_time(session['expires_at']),
          provider_customer_id: session['customer'],
          provider_subscription_id: session['subscription'],
          metadata: filtered_metadata(metadata)
        ).call
      end

      def handle_invoice_paid(event)
        invoice = event.data.object
        metadata = extract_metadata(invoice)
        account_id = metadata_account_id(metadata)
        plan_code = metadata_plan_code(metadata)
        return unless account_id && plan_code

        Billing::AccountPlanUpdater.new(
          account_id: account_id,
          plan_code: plan_code,
          provider: 'stripe',
          seats: metadata_seats(metadata, invoice.dig('lines', 'data', 0, 'quantity')),
          status: 'active',
          current_period_end: timestamp_to_time(invoice['period_end'] || invoice.dig('lines', 'data', 0, 'period', 'end')),
          provider_customer_id: invoice['customer'],
          provider_subscription_id: invoice['subscription'],
          metadata: filtered_metadata(metadata)
        ).call
      end

      def handle_invoice_failed(event, status)
        invoice = event.data.object
        metadata = extract_metadata(invoice)
        update_plan_from_metadata(invoice, metadata, status)
      end

      def handle_subscription_event(event, status)
        subscription = event.data.object
        metadata = extract_metadata(subscription)
        update_plan_from_metadata(subscription, metadata, status)
      end

      def update_plan_from_metadata(object, metadata, status)
        account_id = metadata_account_id(metadata)
        plan_code = metadata_plan_code(metadata)
        return unless account_id && plan_code

        Billing::AccountPlanUpdater.new(
          account_id: account_id,
          plan_code: plan_code,
          provider: 'stripe',
          seats: metadata_seats(metadata, subscription_quantity(object)),
          status: status,
          current_period_end: timestamp_to_time(object['current_period_end'] || object.dig('period', 'end')),
          provider_customer_id: object['customer'],
          provider_subscription_id: object['id'] || object['subscription'],
          metadata: filtered_metadata(metadata)
        ).call
      end

      def extract_metadata(resource)
        base_metadata = safe_hash(resource['metadata'])
        line_item_metadata = safe_hash(resource.dig('lines', 'data', 0, 'metadata'))
        base_metadata.merge(line_item_metadata).with_indifferent_access
      end

      def metadata_account_id(metadata)
        data = metadata.to_h
        return unless data.present?

        raw_value = data['account_id'] || data['accountId']
        return if raw_value.blank?

        raw_value.to_i
      end

      def metadata_plan_code(metadata)
        data = metadata.to_h
        data['plan_code'] || data['planCode']
      end

      def metadata_seats(metadata, fallback = nil)
        data = metadata.to_h
        seats = data['seats'] || data['seatCount'] || fallback
        seats.to_i if seats.present?
      end

      def filtered_metadata(metadata)
        metadata.to_h.except('account_id', 'accountId', 'plan_code', 'planCode', 'seats', 'seatCount')
      end

      def subscription_quantity(resource)
        resource.dig('items', 'data', 0, 'quantity') || resource['quantity']
      end

      def timestamp_to_time(timestamp)
        return if timestamp.blank?

        Time.zone.at(timestamp.to_i)
      rescue StandardError
        nil
      end

      def safe_hash(value)
        return {} if value.blank?

        return value.to_h if value.respond_to?(:to_h)
        return value.to_hash if value.respond_to?(:to_hash)

        value
      end
    end
  end
end
