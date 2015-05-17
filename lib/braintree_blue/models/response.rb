module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class BraintreeBlueResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'braintree_blue_responses'

      has_one :braintree_blue_transaction

      def self.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, response, extra_params = {}, model = ::Killbill::BraintreeBlue::BraintreeBlueResponse)
        super(api_call,
              kb_account_id,
              kb_payment_id,
              kb_payment_transaction_id,
              transaction_type,
              payment_processor_account_id,
              kb_tenant_id,
              response,
              {
		          :params_braintree_customer_id => extract(response, 'braintree_customer','id'),
		          :params_braintree_customer_first_name => extract(response, 'braintree_customer','first_name'),
		          :params_braintree_customer_last_name => extract(response, 'braintree_customer','last_name'),
		          :params_braintree_customer_email => extract(response, 'braintree_customer','email'),
		          :params_braintree_customer_customer_vault_id => extract(response, 'braintree_customer','customer_vault_id'),
		          :params_braintree_customer_credit_card_token => extract(response, 'braintree_customer','credit_card_token'),
                  :params_braintree_customer_credit_card_bin             => extract(response, 'card_response','bin'),
                  :params_braintree_customer_credit_card_expiration_date => extract(response, 'card_response','expiration_date'),
                  :params_braintree_customer_credit_card_last_4          => extract(response, 'card_response','last_4'),
                  :params_braintree_customer_credit_card_card_type       => extract(response, 'card_response','card_type'),
                  :params_braintree_customer_credit_card_masked_number   => extract(response, 'card_response','masked_number')
              }.merge!(extra_params),
              model)
      end

      def self.search_where_clause(t, search_key)
        where_clause = t[:params_braintree_customer_id].eq(search_key)
                   .or(t[:params_braintree_customer_credit_card_token].eq(search_key))

        # Only search successful payments and refunds
        where_clause = where_clause.and(t[:success].eq(true))

        super.or(where_clause)
      end
    end
  end
end
