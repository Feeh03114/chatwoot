class Webhooks::StripeController < PublicController
  skip_before_action :verify_authenticity_token
  around_action :handle_with_exception

  rescue_from CustomExceptions::Billing::ProviderError, with: :render_error_response

  def create
    payload = request.body.read
    signature = request.headers['Stripe-Signature']
    Billing::Stripe::WebhookHandler.new(payload: payload, signature: signature).process
    head :ok
  end
end
