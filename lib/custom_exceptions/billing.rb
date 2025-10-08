# frozen_string_literal: true

module CustomExceptions
  module Billing
    class ProviderError < CustomExceptions::Base
      def message
        I18n.t('errors.billing.provider_error', default: 'Unable to process billing request')
      end

      def http_status
        422
      end

      def to_hash
        super.merge(details: @data)
      end
    end
  end
end
