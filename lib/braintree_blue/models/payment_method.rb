module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class BraintreeBluePaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = 'braintree_blue_payment_methods'

      def self.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, cc_or_token, response, options, extra_params = {}, model = ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod)
        braintree_customer_id = self.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id)

        if braintree_customer_id.blank?
          card_response     = response.params['braintree_customer']['credit_cards'][0]
          customer_response = response.params['braintree_customer']
        elsif response.respond_to?(:responses)
          card_response     = response.responses.first.params
          customer_response = response.responses.last.params
        else
          # Assume that the payment method already exists in Braintree and
          # we're just importing it into KillBill. Useful in conjunction with
          # the skip_gw option. We basically just need to stuff some of the
          # values so that the call below doesn't fail.
          card_response = {
            'expiration_date' => "#{extra_params[:cc_expiration_month]}/#{extra_params[:cc_expiration_year]}"
          }
          customer_response = { 'id' => braintree_customer_id }
        end

        super(kb_account_id,
              kb_payment_method_id,
              kb_tenant_id,
              cc_or_token,
              response,
              options,
              {
                  :braintree_customer_id => customer_response['id'],
                  :token              	 => customer_response['id'],
                  :cc_type               => card_response['card_type'],
                  :cc_exp_month          => card_response['expiration_date'].split('/').first,
                  :cc_exp_year           => card_response['expiration_date'].split('/').last,
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
