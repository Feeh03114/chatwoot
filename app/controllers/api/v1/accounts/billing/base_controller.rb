class Api::V1::Accounts::Billing::BaseController < Api::V1::Accounts::BaseController
  rescue_from CustomExceptions::Billing::ProviderError, with: :render_error_response
end
