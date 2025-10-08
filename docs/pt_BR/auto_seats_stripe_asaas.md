# Automação de Assentos com Stripe e Asaas

Este guia explica, em português, como o Chatwoot atualiza automaticamente o número de agentes (assentos) de uma conta sempre que uma assinatura é vendida via Stripe ou via fluxo de revenda com o Asaas. A arquitetura já está disponível no código e depende apenas da configuração correta dos planos e das credenciais dos provedores de pagamento.

## Visão Geral

1. **Checkout/Assinatura**: o cliente conclui uma compra no Stripe ou no Asaas.
2. **Webhooks**: o provedor envia um evento para os endpoints `/webhooks/stripe` ou `/webhooks/asaas`.
3. **Processamento**: os serviços `Billing::Stripe::WebhookHandler` e `Billing::Asaas::WebhookHandler` interpretam o evento, salvam o histórico em `Billing::WebhookEvent` e chamam o `Billing::AccountPlanUpdater`.
4. **Atualização do Plano**: `Billing::AccountPlanUpdater` grava o plano ativo (`Billing::AccountPlan`) e dispara o `Billing::AccountSeatManager`, que sincroniza os agentes com a quantidade paga.

## Pré-requisitos

1. **Planos cadastrados**
   - Crie registros em `billing_plans` com `code`, `provider` (`stripe` ou `asaas`), `provider_price_id`, `agents_included` e limites/funcionalidades desejados. Utilize seeds ou ActiveAdmin conforme sua rotina.
   - Associe features e limites através das tabelas `billing_plan_features` e `billing_plan_limits` para que `Account#billing_feature_keys` e `Account#usage_limits` reflitam as capacidades do plano.

2. **Credenciais**
   - Preencha as variáveis no `.env` ou na infraestrutura (Kubernetes, Docker, etc.). Os nomes esperados estão listados em `.env.example` (ex.: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `ASAAS_API_KEY`, `ASAAS_WEBHOOK_SECRET`).

3. **Rotas expostas**
   - A rota de checkout do Stripe é acessível via `POST /api/v1/accounts/:account_id/billing/checkout_sessions`.
   - Assinaturas de revenda usam `POST /api/v1/accounts/:account_id/billing/reseller_subscriptions`.
   - Os webhooks públicos são `POST /webhooks/stripe` e `POST /webhooks/asaas`.

## Fluxo do Stripe

1. O dashboard chama `BillingLanding.vue`, que utiliza `app/javascript/dashboard/api/billing.js` para criar uma sessão de checkout (`CheckoutSessionsController`).
2. Após o pagamento, o Stripe envia `invoice.paid` (e outros eventos) para `/webhooks/stripe`.
3. `Billing::Stripe::WebhookHandler` valida a assinatura do evento, registra-o e invoca:
   ```ruby
   Billing::AccountPlanUpdater.new(
     account_id: account_id,
     plan_code: plan_code,
     provider: 'stripe',
     seats: seats_from_event,
     status: subscription_status,
     current_period_end: period_end,
     provider_customer_id: stripe_customer_id,
     provider_subscription_id: stripe_subscription_id
   ).call
   ```
4. O `AccountPlanUpdater` persiste as informações e chama `Billing::AccountSeatManager#sync!`, que compara `seats_allocated` com os agentes existentes.
5. Se houver vagas disponíveis, nada é removido; se houver excesso, os agentes mais antigos são removidos primeiro, respeitando papéis de agente antes de administradores.

## Fluxo do Asaas (Revenda)

1. O formulário de revenda da landing envia dados para `ResellerSubscriptionsController`, que chama `Billing::Asaas::SubscriptionService`.
2. O serviço cria/recupera o customer no Asaas, dispara a assinatura e armazena o ID do contrato.
3. Quando um pagamento é reconhecido, o webhook `payment.received` chega em `/webhooks/asaas`.
4. `Billing::Asaas::WebhookHandler` replica o mesmo ciclo do Stripe, atualizando o plano da conta e sincronizando os assentos.

## Enforcement automático

- `Billing::AccountSeatManager` calcula quantos `AccountUser` podem permanecer. Se o número atual superar `seats_allocated`, o serviço remove os usuários excedentes e atualiza `seats_used`.
- Métodos utilitários como `Account#seats_allocated`, `Account#billing_feature_keys` e `Account#usage_limits` usam o plano ativo (`active_billing_account_plan`) para refletir limites no restante do sistema.

## Passo a passo para ativar

1. **Cadastrar planos** com `provider = 'stripe'` (venda direta) e/ou `provider = 'asaas'` (revenda).
2. **Informar os preços** correspondentes (`provider_price_id` ou `planId`).
3. **Configurar variáveis de ambiente** e reiniciar a aplicação.
4. **Apontar webhooks** do Stripe e Asaas para as rotas públicas da sua instalação.
5. **Testar**: gere uma compra de teste e verifique se `Billing::AccountPlan` recebeu o novo `seats_allocated` e se a lista de agentes foi ajustada automaticamente.

Seguindo esses passos, cada nova contratação ajusta o número de agentes permitidos, mantendo o Chatwoot em conformidade com o plano pago.
