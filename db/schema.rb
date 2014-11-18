require 'active_record'

ActiveRecord::Schema.define(:version => 20140410153635) do
  create_table "braintree_blue_payment_methods", :force => true do |t|
    t.string   "kb_payment_method_id"      # NULL before Kill Bill knows about it
    t.string   "token"                     # braintree_blue id
    t.string   "braintree_customer_id"  
    t.string   "cc_first_name"
    t.string   "cc_last_name"
    t.string   "cc_type"
    t.integer  "cc_exp_month"
    t.integer  "cc_exp_year"
    t.integer  "cc_number"
    t.integer  "cc_last_4"
    t.integer  "cc_start_month"
    t.integer  "cc_start_year"
    t.integer  "cc_issue_number"
    t.integer  "cc_verification_value"
    t.integer  "cc_track_data"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.boolean  "is_deleted",               :null => false, :default => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "kb_account_id"
    t.string   "kb_tenant_id"
  end

  add_index(:braintree_blue_payment_methods, :kb_account_id)
  add_index(:braintree_blue_payment_methods, :kb_payment_method_id)

  create_table "braintree_blue_transactions", :force => true do |t|
    t.integer  "braintree_blue_response_id",  :null => false
    t.string   "api_call",                       :null => false
    t.string   "kb_payment_id",                  :null => false
    t.string   "kb_payment_transaction_id",      :null => false
    t.string   "transaction_type",               :null => false
    t.string   "txn_id"                          # braintree_blue transaction id
    t.integer  "amount_in_cents",                :null => false
    t.string   "currency",                       :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "kb_account_id",                  :null => false
    t.string   "kb_tenant_id",                   :null => false
  end

  add_index(:braintree_blue_transactions, :kb_payment_id)

  create_table "braintree_blue_responses", :force => true do |t|
    t.string   "api_call",          :null => false
    t.string   "kb_payment_id"
    t.string   "kb_payment_transaction_id"
    t.string   "transaction_type"
    t.string   "message"
    t.string   "authorization"
    t.boolean  "fraud_review"
    t.boolean  "test"
    t.string   "params_braintree_customer_email"
    t.string   "params_braintree_customer_first_name"
    t.string   "params_braintree_customer_last_name"
    t.string   "params_braintree_customer_id"
    t.string   "params_braintree_customer_customer_vault_id"
    t.string   "params_braintree_customer_credit_card_token"
    t.string   "params_braintree_customer_credit_card_bin"
    t.string   "params_braintree_customer_credit_card_expiration_date"
    t.string   "params_braintree_customer_credit_card_last_4"
    t.string   "params_braintree_customer_credit_card_card_type"
    t.string   "params_braintree_customer_credit_card_masked_number"  
    t.boolean  "paramt_exists"
    t.string   "avs_result_code"
    t.string   "avs_result_message"
    t.string   "avs_result_street_match"
    t.string   "avs_result_postal_match"
    t.string   "cvv_result_code"
    t.string   "cvv_result_message"
    t.boolean  "success"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "kb_account_id"
    t.string   "kb_tenant_id"
  end
end
