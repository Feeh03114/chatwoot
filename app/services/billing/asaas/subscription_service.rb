# frozen_string_literal: true

module Billing
  module Asaas
    class SubscriptionService
      def initialize(account:, plan_code:, customer_attributes:, payment_method:, seats: nil, addons: {})
        @account = account
        @plan_code = plan_code
        @customer_attributes = customer_attributes.to_h.with_indifferent_access
        @payment_method = payment_method.presence || 'BOLETO'
        @seats = seats
        @addons = (addons || {}).to_h
      end

      def call
        plan = Billing::Plan.published.find_by!(code: plan_code, provider: 'asaas')
        client = Billing::Asaas::Client.new

        customer = ensure_customer(client)
        subscription = client.create_subscription(subscription_payload(plan, customer))
        create_addons(client, customer, subscription)

        account_plan = Billing::AccountPlanUpdater.new(
          account_id: account.id,
          plan_code: plan.code,
          provider: 'asaas',
          seats: normalized_seats || plan.agents_included,
          status: 'active',
          current_period_end: parse_date(subscription['nextDueDate']),
          provider_customer_id: customer['id'],
          provider_subscription_id: subscription['id'],
          metadata: {
            asaas_subscription_id: subscription['id'],
            asaas_customer_id: customer['id'],
            addons: addons
          }
        ).call

        {
          subscription: subscription,
          customer: customer,
          account_plan: account_plan
        }
      end

      private

      attr_reader :account, :plan_code, :customer_attributes, :payment_method, :seats, :addons

      def ensure_customer(client)
        existing_customer = client.find_customer_by_email(customer_attributes[:email]) if customer_attributes[:email].present?
        return existing_customer if existing_customer.present?

        client.create_customer(customer_attributes)
      end

      def subscription_payload(plan, customer)
        {
          customer: customer['id'],
          billingType: payment_method,
          value: plan.price_cents / 100.0,
          cycle: normalize_cycle(plan.billing_cycle),
          description: plan.name,
          externalReference: metadata_reference(plan),
          maxPayments: normalized_seats || plan.agents_included
        }
      end

      def create_addons(client, customer, subscription)
        return if addons.blank?

        addons.each do |key, value|
          client.create_additional_charge(
            customer: customer['id'],
            value: value.to_f,
            description: "Addon: #{key}",
            billingType: payment_method,
            dueDate: subscription['nextDueDate'],
            externalReference: "addon-#{key}-#{subscription['id']}"
          )
        end
      end

      def normalize_cycle(billing_cycle)
        case billing_cycle
        when 'monthly'
          'MONTHLY'
        when 'yearly', 'annual', 'annually'
          'ANNUAL'
        else
          billing_cycle&.upcase
        end
      end

      def metadata_reference(plan)
        {
          account_id: account.id,
          plan_code: plan.code,
          seats: normalized_seats || plan.agents_included,
          generated_at: Time.zone.now.iso8601
        }.to_json
      end

      def normalized_seats
        return unless seats.present?

        seats.to_i.positive? ? seats.to_i : nil
      end

      def parse_date(value)
        return if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
