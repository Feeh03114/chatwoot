# Billing Integrations Overview

This guide explains how Chatwoot's self-hosted billing extensions integrate with Stripe and Asaas to automate seat allocation, expose reseller workflows, and connect landing page conversions to your workspace limits.

> **Prefer to read in Portuguese?** Confira o documento complementar [Automação de Assentos com Stripe e Asaas](pt_BR/auto_seats_stripe_asaas.md) que descreve o mesmo fluxo passo a passo.

## Prerequisites

- A Chatwoot workspace running the custom billing stack.
- Stripe account with subscription products and prices configured for each plan code you intend to sell directly.
- Asaas account enabled for subscription billing when acting as a reseller.
- Middleware secrets configured in the environment (see [Environment Variables](#environment-variables)).

## Stripe Subscription Flow

1. **Plan catalogue** – Plans exposed to Stripe must be created in the `billing_plans` table with `provider` set to `stripe` and the corresponding `provider_price_id`.
2. **Checkout session** – The dashboard uses `Api::V1::Accounts::Billing::CheckoutSessionsController` to open a checkout session that references the plan code and the current account. The controller delegates to `Billing::Stripe::CheckoutSessionService`, which builds the session with the success and cancel URLs.
3. **Webhook processing** – Stripe events are delivered to `Webhooks::StripeController`, which forwards validated payloads to `Billing::Stripe::WebhookHandler`. The handler records events, upserts account plan rows, and recalculates limits.
4. **Seat enforcement** – When invoices are paid, `Billing::AccountPlanUpdater` and `Billing::AccountSeatManager` adjust `seats_allocated` and ensure active agents do not exceed the purchased quantity.

When a customer purchases additional seats via Stripe, the webhook handler increases `seats_allocated`, triggering the seat manager to activate pending agents or deactivate overflow users until the account matches the paid capacity.

## Asaas Reseller Flow

1. **Plan catalogue** – Plans sold via Asaas must exist in `billing_plans` with `provider` set to `asaas` and the reseller metadata stored in `metadata`.
2. **Reseller subscription** – The dashboard's reseller workflow calls `Api::V1::Accounts::Billing::ResellerSubscriptionsController`, which orchestrates customer creation and subscription provisioning through `Billing::Asaas::SubscriptionService`.
3. **Webhook processing** – Asaas payment events reach `Webhooks::AsaasController` and are delegated to `Billing::Asaas::WebhookHandler` to upsert plan assignments and recompute seat limits.
4. **Seat enforcement** – The same `Billing::AccountSeatManager` enforces limits after each webhook update, keeping agents aligned with the purchased allotment.

## Landing Page Entry Points

The billing landing screen (`BillingLanding.vue`) provides call-to-action buttons that initiate Stripe checkout or collect reseller data before invoking the Asaas workflow. All server calls flow through the shared `app/javascript/dashboard/api/billing.js` client.

## Environment Variables

Add the following variables to `.env` (or your deployment secrets) to activate the billing integrations:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `ASAAS_API_KEY`
- `ASAAS_WEBHOOK_SECRET`
- `FRONTEND_URL` (optional override for checkout redirects)

## Operational Checklist

- Verify Stripe and Asaas webhooks are reachable from your deployment and the secrets are correct.
- Seed the plans, features, and limits tables with the plan catalogue your business offers.
- Confirm the seat manager job runs after webhook events and when administrators adjust allocations manually.
- Test downgrade scenarios to ensure surplus agents are deactivated in line with the reduced seat count.
