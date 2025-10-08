<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import BillingAPI from 'dashboard/api/billing';
import PlanCard from './PlanCard.vue';
import InputV4 from 'dashboard/components-next/input/Input.vue';
import ButtonV4 from 'next/button/Button.vue';

const { t } = useI18n();

const state = reactive({
  plans: [],
  currentPlan: null,
  limits: {},
  features: [],
  loading: false,
  submitting: false,
  error: '',
  success: '',
});

const seatOverrides = reactive({});
const resellerPlan = ref(null);
const resellerPlanName = computed(() => resellerPlan.value?.name || '');
const resellerFormVisible = ref(false);
const resellerForm = reactive({
  name: '',
  email: '',
  phone: '',
  document: '',
  payment_method: 'PIX',
  seats: '',
});

const hasPlans = computed(() => state.plans.length > 0);

const seatsForPlan = plan => {
  const value = seatOverrides[plan.code];
  return value && Number(value) > 0 ? Number(value) : plan.agents_included;
};

const updateSeats = (planCode, value) => {
  seatOverrides[planCode] = Number(value) || '';
};

const resetMessages = () => {
  state.error = '';
  state.success = '';
};

const fetchPlans = async () => {
  try {
    state.loading = true;
    const response = await BillingAPI.getPlan();
    state.plans = response.data.plans || [];
    state.currentPlan = response.data.plan || null;
    state.limits = response.data.limits || {};
    state.features = response.data.features || [];
    if (state.currentPlan?.plan?.code) {
      seatOverrides[state.currentPlan.plan.code] =
        state.currentPlan.seats?.allocated;
    }
  } catch (error) {
    state.error = error?.response?.data?.error || error.message;
  } finally {
    state.loading = false;
  }
};

const handleCheckout = async plan => {
  resetMessages();
  try {
    state.submitting = true;
    const quantity = seatsForPlan(plan);
    const response = await BillingAPI.createCheckoutSession({
      plan_code: plan.code,
      quantity,
      success_url: window.location.href,
      cancel_url: window.location.href,
      metadata: {
        seats: quantity,
      },
    });
    window.location.href = response.data.checkout_url;
  } catch (error) {
    state.error = error?.response?.data?.error || error.message;
  } finally {
    state.submitting = false;
  }
};

const openResellerForm = plan => {
  resetMessages();
  resellerPlan.value = plan;
  resellerFormVisible.value = true;
  resellerForm.seats = seatsForPlan(plan);
};

const compactObject = object =>
  Object.fromEntries(
    Object.entries(object).filter(
      ([, value]) => value !== undefined && value !== null && value !== ''
    )
  );

const submitReseller = async () => {
  if (!resellerPlan.value) return;
  resetMessages();
  try {
    state.submitting = true;
    const seats =
      Number(resellerForm.seats) > 0
        ? Number(resellerForm.seats)
        : resellerPlan.value.agents_included;
    const payload = {
      plan_code: resellerPlan.value.code,
      payment_method: resellerForm.payment_method,
      seats,
      customer: compactObject({
        name: resellerForm.name,
        email: resellerForm.email,
        cpfCnpj: resellerForm.document,
        mobilePhone: resellerForm.phone,
      }),
    };
    await BillingAPI.createResellerSubscription(payload);
    state.success = t('BILLING_LANDING.SUCCESS_RESELLER');
    resellerFormVisible.value = false;
    resellerPlan.value = null;
    await fetchPlans();
  } catch (error) {
    state.error = error?.response?.data?.error || error.message;
  } finally {
    state.submitting = false;
  }
};

const closeResellerForm = () => {
  resetMessages();
  resellerFormVisible.value = false;
  resellerPlan.value = null;
};

onMounted(fetchPlans);
</script>

<template>
  <div class="space-y-6">
    <section class="rounded-2xl border border-n-weak bg-white p-6 shadow-sm">
      <div class="flex flex-col gap-2">
        <h2 class="text-2xl font-semibold text-n-900">
          {{ t('BILLING_LANDING.TITLE') }}
        </h2>
        <p class="text-sm text-n-600">
          {{ t('BILLING_LANDING.DESCRIPTION') }}
        </p>
        <div
          v-if="state.currentPlan?.plan"
          class="mt-4 rounded-xl border border-n-alpha-black5 bg-n-alpha-black3 p-4"
        >
          <h3 class="text-sm font-semibold text-n-700 uppercase tracking-wide">
            {{ t('BILLING_LANDING.CURRENT_PLAN.TITLE') }}
          </h3>
          <div class="mt-2 grid gap-3 md:grid-cols-3 text-sm text-n-700">
            <div>
              <p class="font-medium text-n-600">
                {{ t('BILLING_LANDING.CURRENT_PLAN.NAME') }}
              </p>
              <p class="mt-1 text-n-900">
                {{ state.currentPlan.plan?.name }}
              </p>
            </div>
            <div>
              <p class="font-medium text-n-600">
                {{ t('BILLING_LANDING.CURRENT_PLAN.SEATS') }}
              </p>
              <p class="mt-1 text-n-900">
                {{ state.currentPlan.seats?.allocated ?? 0 }} /
                {{ state.currentPlan.seats?.used ?? 0 }}
              </p>
            </div>
            <div>
              <p class="font-medium text-n-600">
                {{ t('BILLING_LANDING.CURRENT_PLAN.STATUS') }}
              </p>
              <p class="mt-1 capitalize text-n-900">
                {{ state.currentPlan.status }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="space-y-4">
      <header class="flex flex-col gap-2">
        <h3 class="text-xl font-semibold text-n-900">
          {{ t('BILLING_LANDING.PRICING_TITLE') }}
        </h3>
        <p class="text-sm text-n-600">
          {{ t('BILLING_LANDING.PRICING_SUBTITLE') }}
        </p>
      </header>

      <div
        v-if="state.loading"
        class="flex items-center justify-center rounded-2xl border border-dashed border-n-weak p-10"
      >
        <span class="text-sm text-n-600">{{
          t('BILLING_LANDING.LOADING')
        }}</span>
      </div>
      <div
        v-else-if="!hasPlans"
        class="rounded-2xl border border-dashed border-n-weak p-10 text-center text-sm text-n-600"
      >
        {{ t('BILLING_LANDING.NO_PLANS') }}
      </div>
      <div v-else class="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        <PlanCard
          v-for="plan in state.plans"
          :key="plan.code"
          :plan="plan"
          :loading="state.submitting"
          @checkout="handleCheckout"
          @reseller="openResellerForm"
        >
          <template #details="{ plan }">
            <div class="space-y-2">
              <InputV4
                :label="t('BILLING_LANDING.SEATS_LABEL')"
                type="number"
                min="1"
                :model-value="seatsForPlan(plan)"
                @update:model-value="value => updateSeats(plan.code, value)"
              />
              <p class="text-xs text-n-600">
                {{
                  t('BILLING_LANDING.SEATS_HELP', {
                    count: plan.agents_included,
                  })
                }}
              </p>
            </div>
          </template>
        </PlanCard>
      </div>
    </section>

    <transition name="fade">
      <section
        v-if="resellerFormVisible && resellerPlan"
        class="rounded-2xl border border-n-weak bg-white p-6 shadow-sm space-y-4"
      >
        <header class="space-y-1">
          <h3 class="text-lg font-semibold text-n-900">
            {{
              t('BILLING_LANDING.RESELLER_FORM.TITLE', {
                plan: resellerPlanName,
              })
            }}
          </h3>
          <p class="text-sm text-n-600">
            {{ t('BILLING_LANDING.RESELLER_FORM.DESCRIPTION') }}
          </p>
        </header>
        <div class="grid gap-4 md:grid-cols-2">
          <InputV4
            v-model="resellerForm.name"
            :label="t('BILLING_LANDING.RESELLER_FORM.NAME')"
            autocomplete="name"
          />
          <InputV4
            v-model="resellerForm.email"
            :label="t('BILLING_LANDING.RESELLER_FORM.EMAIL')"
            type="email"
            autocomplete="email"
          />
          <InputV4
            v-model="resellerForm.phone"
            :label="t('BILLING_LANDING.RESELLER_FORM.PHONE')"
            autocomplete="tel"
          />
          <InputV4
            v-model="resellerForm.document"
            :label="t('BILLING_LANDING.RESELLER_FORM.DOCUMENT')"
          />
          <InputV4
            v-model="resellerForm.seats"
            :label="t('BILLING_LANDING.RESELLER_FORM.SEATS')"
            type="number"
            min="1"
          />
          <InputV4
            v-model="resellerForm.payment_method"
            :label="t('BILLING_LANDING.RESELLER_FORM.PAYMENT_METHOD')"
          />
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <ButtonV4
            solid
            blue
            :disabled="state.submitting"
            @click="submitReseller"
          >
            {{ t('BILLING_LANDING.RESELLER_FORM.SUBMIT') }}
          </ButtonV4>
          <ButtonV4
            faded
            slate
            :disabled="state.submitting"
            @click="closeResellerForm"
          >
            {{ t('BILLING_LANDING.RESELLER_FORM.CANCEL') }}
          </ButtonV4>
        </div>
      </section>
    </transition>

    <div
      v-if="state.error"
      class="rounded-lg border border-n-ruby-6 bg-n-ruby-1 p-4 text-sm text-n-ruby-9"
    >
      {{ state.error }}
    </div>
    <div
      v-if="state.success"
      class="rounded-lg border border-n-teal-7 bg-n-teal-1 p-4 text-sm text-n-teal-12"
    >
      {{ state.success }}
    </div>
  </div>
</template>
