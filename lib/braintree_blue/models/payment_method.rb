module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class BraintreeBluePaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = 'braintree_blue_payment_methods'

      # Note: the ActiveMerchant Braintree implementation puts the customer id in the authorization field, not the token
      def self.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, b_customer_id, response, options, extra_params = {}, model = ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod)
        braintree_customer_id = options[:customer] || b_customer_id || self.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id)

        primary_response = response.respond_to?(:responses) ? response.primary_response : response

        # Unfortunately, the ActiveMerchant Braintree implementation will drop that information when adding a card to an existing customer
        customer_response = primary_response.params['braintree_customer'] || {}

        # See active_merchant.rb
        token = options[:token] || primary_response.params['token']
        card_response = (customer_response['credit_cards'] || []).first || {}
        cc_exp_dates = (card_response['expiration_date'] || '').split('/')

        super(kb_account_id,
              kb_payment_method_id,
              kb_tenant_id,
              token,
              response,
              options,
              {
                  :braintree_customer_id => braintree_customer_id,
                  :token                 => token,
                  :cc_type               => card_response['card_type'],
                  :cc_exp_month          => cc_exp_dates.first,
                  :cc_exp_year           => cc_exp_dates.last,
                  :cc_last_4             => card_response['last_4'],
                  :cc_first_name         => customer_response['first_name'],
                  :cc_last_name          => customer_response['last_name']
              }.merge!(extra_params),
              model)
      end

      def self.search_where_clause(t, search_key)
        super.or(t[:braintree_customer_id].eq(search_key))
      end

      def self.braintree_customer_id_from_kb_account_id(kb_account_id, tenant_id)
        pms = from_kb_account_id(kb_account_id, tenant_id)
        return nil if pms.empty?

        braintree_customer_ids = Set.new
        pms.each { |pm| braintree_customer_ids << pm.braintree_customer_id }
        raise "No Braintree customer id found for account #{kb_account_id}" if braintree_customer_ids.empty?
        raise "Kill Bill account #{kb_account_id} mapping to multiple Braintree customers: #{braintree_customer_ids}" if braintree_customer_ids.size > 1
        braintree_customer_ids.first
      end
    end
  end
end
