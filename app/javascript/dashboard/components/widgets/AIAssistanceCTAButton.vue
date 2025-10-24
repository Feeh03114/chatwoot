<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['open']);

const onClick = () => {
  emit('open');
};
</script>

<template>
  <div class="relative">
    <NextButton
      class="cta-btn cta-btn-light dark:cta-btn-dark hover:cta-btn-light-hover dark:hover:cta-btn-dark-hover"
      :label="$t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST')"
      icon="i-ph-magic-wand"
      sm
      @click="onClick"
    />

    <div
      class="radar-ping-animation absolute top-0 right-0 -mt-1 -mr-1 rounded-full w-3 h-3 bg-n-iris-9"
    />
    <div
      class="absolute top-0 right-0 -mt-1 -mr-1 rounded-full w-3 h-3 bg-n-iris-9 opacity-50"
    />
  </div>
</template>

<style scoped>
@tailwind components;

@layer components {
  /* Gradient animation */
  @keyframes gradient {
    0% {
      background-position: 0% 50%;
    }

    50% {
      background-position: 100% 50%;
    }

    100% {
      background-position: 0% 50%;
    }
  }

  .cta-btn {
    animation: gradient 5s ease infinite;
    @apply text-n-slate-12 border-0 text-xs;
  }

  .cta-btn-light {
    background: linear-gradient(
        255.98deg,
        rgba(0, 192, 164, 0.24) 12%,
        rgba(34, 244, 0, 0.18) 84%
      ),
      linear-gradient(
        0deg,
        rgb(var(--slate-2)),
        rgb(var(--slate-2))
      );
  }

  .cta-btn-dark {
    background: linear-gradient(
        255.98deg,
        rgba(0, 192, 164, 0.24) 12%,
        rgba(34, 244, 0, 0.18) 84%
      ),
      linear-gradient(
        0deg,
        rgb(var(--slate-4)),
        rgb(var(--slate-4))
      );
  }

  .cta-btn-light-hover {
    background: linear-gradient(
        255.98deg,
        rgba(0, 192, 164, 0.24) 12%,
        rgba(34, 244, 0, 0.18) 84%
      ),
      linear-gradient(
        0deg,
        rgb(var(--slate-3)),
        rgb(var(--slate-3))
      );
  }

  .cta-btn-dark-hover {
    background: linear-gradient(
        255.98deg,
        rgba(0, 192, 164, 0.24) 12%,
        rgba(34, 244, 0, 0.18) 84%
      ),
      linear-gradient(
        0deg,
        rgb(var(--slate-6)),
        rgb(var(--slate-6))
      );
  }

  /* Radar ping animation */
  @keyframes ping {
    75%,
    100% {
      transform: scale(2);
      opacity: 0;
    }
  }

  .radar-ping-animation {
    animation: ping 1s ease infinite;
  }
}
</style>
