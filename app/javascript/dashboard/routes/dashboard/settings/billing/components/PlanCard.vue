<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  plan: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['checkout', 'reseller']);

const { t } = useI18n();

const formattedPrice = computed(() => {
  const price = Number(props.plan.price_cents || 0) / 100;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: (props.plan.currency || 'USD').toUpperCase(),
    minimumFractionDigits: 2,
  }).format(price);
});
</script>

<template>
  <div class="rounded-xl border border-n-weak bg-white p-6 shadow-sm space-y-4">
    <header>
      <p class="text-sm font-medium text-n-600 uppercase tracking-wide">
        {{ plan.code }}
      </p>
      <h3 class="mt-1 text-xl font-semibold text-n-900">
        {{ plan.name }}
      </h3>
      <p class="text-sm text-n-600 capitalize">
        {{ plan.billing_cycle }}
      </p>
    </header>
    <div class="text-3xl font-bold text-n-900">
      {{ formattedPrice }}
      <span class="text-sm font-medium text-n-600">
        / {{ plan.billing_cycle }}
      </span>
    </div>
    <section class="space-y-2">
      <slot name="details" :plan="plan" />
      <div class="text-sm font-semibold text-n-700">
        {{ t('BILLING_LANDING.FEATURES_TITLE') }}
      </div>
      <ul class="space-y-2">
        <li
          v-for="feature in plan.features"
          :key="feature"
          class="flex items-start gap-2 text-sm text-n-700"
        >
          <span class="i-lucide-check-circle-2 mt-0.5 text-green-600" />
          <span class="capitalize">{{ feature.replace(/_/g, ' ') }}</span>
        </li>
      </ul>
    </section>
    <footer class="space-y-2">
      <slot
        name="actions"
        :plan="plan"
        :loading="loading"
        :checkout="() => emit('checkout', plan)"
        :reseller="() => emit('reseller', plan)"
      >
        <ButtonV4
          block
          solid
          blue
          :disabled="loading"
          data-test="plan-checkout"
          @click="emit('checkout', plan)"
        >
          {{ t('BILLING_LANDING.ACTIONS.CHECKOUT') }}
        </ButtonV4>
        <ButtonV4
          block
          faded
          slate
          :disabled="loading"
          data-test="plan-reseller"
          @click="emit('reseller', plan)"
        >
          {{ t('BILLING_LANDING.ACTIONS.RESALE') }}
        </ButtonV4>
      </slot>
    </footer>
  </div>
</template>
