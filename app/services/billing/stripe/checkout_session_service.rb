# frozen_string_literal: true

module Billing
  module Stripe
    class CheckoutSessionService
      def initialize(account:, plan:, success_url:, cancel_url:, quantity: nil, metadata: {})
        raise ArgumentError, 'Stripe plan required' unless plan.provider == 'stripe'

        @account = account
        @plan = plan
        @success_url = success_url
        @cancel_url = cancel_url
        seats = (quantity.presence || plan.agents_included).to_i
        @quantity = seats.positive? ? seats : 1
        @metadata = metadata || {}
      end

      def call
        ::Stripe::Checkout::Session.create(
          mode: 'subscription',
          line_items: [
            {
              price: plan.provider_price_id,
              quantity: quantity
            }
          ],
          success_url: success_url,
          cancel_url: cancel_url,
          metadata: prepared_metadata,
          subscription_data: {
            metadata: prepared_metadata
          }
        )
      end

      private

      attr_reader :account, :plan, :success_url, :cancel_url, :quantity, :metadata

      def prepared_metadata
        base_metadata.merge(metadata || {}).transform_keys(&:to_s)
      end

      def base_metadata
        {
          account_id: account.id,
          plan_code: plan.code,
          seats: quantity
        }
      end
    end
  end
end
