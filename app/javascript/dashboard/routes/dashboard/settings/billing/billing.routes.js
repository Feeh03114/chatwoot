import { frontendURL } from '../../../../helper/URLHelper';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import BillingLanding from './components/BillingLanding.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/billing'),
      meta: {
        permissions: ['administrator'],
        installationTypes: [
          INSTALLATION_TYPES.CLOUD,
          INSTALLATION_TYPES.COMMUNITY,
          INSTALLATION_TYPES.ENTERPRISE,
        ],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'BILLING_SETTINGS.TITLE',
        icon: 'credit-card-person',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'billing_settings_index',
          component: Index,
          meta: {
            installationTypes: [
              INSTALLATION_TYPES.CLOUD,
              INSTALLATION_TYPES.COMMUNITY,
              INSTALLATION_TYPES.ENTERPRISE,
            ],
            permissions: ['administrator'],
          },
        },
        {
          path: 'landing',
          name: 'billing_settings_landing',
          component: BillingLanding,
          meta: {
            installationTypes: [
              INSTALLATION_TYPES.CLOUD,
              INSTALLATION_TYPES.COMMUNITY,
              INSTALLATION_TYPES.ENTERPRISE,
            ],
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
