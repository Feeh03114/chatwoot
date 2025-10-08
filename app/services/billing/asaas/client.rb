# frozen_string_literal: true

module Billing
  module Asaas
    class Client
      BASE_URL = ENV.fetch('ASAAS_API_URL', 'https://api.asaas.com/v3').freeze

      def initialize(api_key: ENV.fetch('ASAAS_API_KEY', nil))
        @api_key = api_key
        raise CustomExceptions::Billing::ProviderError.new(error: 'missing_api_key') if @api_key.blank?
      end

      def find_customer_by_email(email)
        response = request(:get, '/customers', query: { email: email })
        customers = response['data'] || []
        customers.first
      end

      def create_customer(payload)
        request(:post, '/customers', body: payload)
      end

      def create_subscription(payload)
        request(:post, '/subscriptions', body: payload)
      end

      def create_additional_charge(payload)
        request(:post, '/payments', body: payload)
      end

      private

      attr_reader :api_key

      def request(method, path, body: nil, query: {})
        options = {
          headers: headers,
          query: query.compact
        }
        options[:body] = body.to_json if body.present?

        response = HTTParty.send(method, "#{BASE_URL}#{path}", options)
        return response.parsed_response if response.success?

        raise CustomExceptions::Billing::ProviderError.new(
          error: 'asaas_request_failed',
          status: response.code,
          response: response.parsed_response
        )
      rescue SocketError, Errno::ECONNREFUSED => e
        raise CustomExceptions::Billing::ProviderError.new(error: 'asaas_connection_failed', detail: e.message)
      end

      def headers
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'access_token' => api_key
        }
      end
    end
  end
end
