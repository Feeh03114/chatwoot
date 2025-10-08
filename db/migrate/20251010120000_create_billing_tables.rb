class CreateBillingTables < ActiveRecord::Migration[7.1]
  def change
    create_table :billing_plans do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: 'brl'
      t.string :billing_cycle, null: false
      t.string :provider, null: false
      t.string :provider_price_id
      t.integer :agents_included, null: false, default: 1
      t.integer :extra_agent_price_cents, null: false, default: 0
      t.boolean :public, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :billing_plans, :code, unique: true
    add_index :billing_plans, [:provider, :provider_price_id], unique: true, name: 'index_billing_plans_on_provider_and_price_id'

    create_table :billing_features do |t|
      t.string :key, null: false
      t.string :description

      t.timestamps
    end

    add_index :billing_features, :key, unique: true

    create_table :billing_plan_features do |t|
      t.references :plan, null: false, foreign_key: { to_table: :billing_plans }
      t.references :feature, null: false, foreign_key: { to_table: :billing_features }

      t.timestamps
    end

    add_index :billing_plan_features, [:plan_id, :feature_id], unique: true, name: 'index_billing_plan_features_on_plan_id_and_feature_id'

    create_table :billing_plan_limits do |t|
      t.references :plan, null: false, foreign_key: { to_table: :billing_plans }
      t.string :limit_key, null: false
      t.integer :limit_value, null: false, default: 0

      t.timestamps
    end

    add_index :billing_plan_limits, [:plan_id, :limit_key], unique: true, name: 'index_billing_plan_limits_on_plan_id_and_limit_key'

    create_table :billing_account_plans do |t|
      t.references :account, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: { to_table: :billing_plans }
      t.string :status, null: false, default: 'active'
      t.datetime :current_period_end
      t.string :provider, null: false
      t.string :provider_customer_id
      t.string :provider_subscription_id
      t.integer :seats_allocated, null: false, default: 0
      t.integer :seats_used, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :billing_account_plans, [:account_id, :provider], unique: true, name: 'index_billing_account_plans_on_account_and_provider'
    add_index :billing_account_plans, :provider_subscription_id, unique: true

    create_table :billing_webhook_events do |t|
      t.string :provider, null: false
      t.string :event_type, null: false
      t.string :event_id, null: false
      t.datetime :processed_at, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :billing_webhook_events, [:provider, :event_id], unique: true, name: 'index_billing_webhook_events_on_provider_and_event_id'
  end
end
