class Webhooks::AsaasController < PublicController
  skip_before_action :verify_authenticity_token
  around_action :handle_with_exception

  rescue_from CustomExceptions::Billing::ProviderError, with: :render_error_response

  def create
    payload = request.body.read
    Billing::Asaas::WebhookHandler.new(payload: payload, signature: request.headers['X-Hook-Signature']).process
    head :ok
  end
end
