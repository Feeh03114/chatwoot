# frozen_string_literal: true

module Billing
  class AccountSeatManager
    def initialize(account_plan)
      @account_plan = account_plan
      @account = account_plan.account
    end

    def sync!
      account_plan.with_lock do
        prune_overage
        refresh_seat_usage
      end
    end

    private

    attr_reader :account_plan, :account

    def prune_overage
      allowed = account_plan.seats_allocated.to_i
      return if allowed.zero?

      current_users = account.account_users.order(created_at: :asc)
      overflow = current_users.count - allowed
      return if overflow <= 0

      removable_account_users = prioritized_users(current_users, overflow)
      removable_account_users.each(&:destroy!)
    end

    def prioritized_users(current_users, limit)
      removable = []
      agent_scope = current_users.where(role: AccountUser.roles[:agent])
      removable.concat(agent_scope.limit(limit))

      remaining = limit - removable.length
      return removable if remaining <= 0

      fallback_scope = current_users.where.not(id: removable.map(&:id)).limit(remaining)
      removable + fallback_scope
    end

    def refresh_seat_usage
      account_plan.update!(seats_used: account.account_users.count)
    end
  end
end
