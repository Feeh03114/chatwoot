/* global axios */
import ApiClient from './ApiClient';

class AccountBillingAPI extends ApiClient {
  constructor() {
    super('billing', { accountScoped: true });
  }

  getPlan() {
    return axios.get(`${this.url}/plan`);
  }

  allocateSeats(payload) {
    return axios.post(`${this.url}/seat_allocation`, {
      seat_allocation: payload,
    });
  }

  createCheckoutSession(payload) {
    return axios.post(`${this.url}/checkout_session`, {
      checkout_session: payload,
    });
  }

  createResellerSubscription(payload) {
    return axios.post(`${this.url}/reseller_subscriptions`, {
      reseller_subscription: payload,
    });
  }
}

export default new AccountBillingAPI();
