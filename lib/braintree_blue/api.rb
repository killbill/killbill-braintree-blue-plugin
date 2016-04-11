module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class PaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PaymentPlugin

      def initialize
        gateway_builder = Proc.new do |config|
          ::ActiveMerchant::Billing::BraintreeBlueGateway.application_id = config[:channel] || 'killbill_SP'
          ::ActiveMerchant::Billing::BraintreeBlueGateway.new :merchant_id => config[:merchant_id],
                                                              :public_key  => config[:public_key],
                                                              :private_key => config[:private_key]
        end

        super(gateway_builder,
              :braintree_blue,
              ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod,
              ::Killbill::BraintreeBlue::BraintreeBlueTransaction,
              ::Killbill::BraintreeBlue::BraintreeBlueResponse)
      end

      def on_event(event)
        # Require to deal with per tenant configuration invalidation
        super(event)
        #
        # Custom event logic could be added below...
        #
      end

      def authorize_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        options = {
          :payment_method_token => true
        }

        options.merge(get_merchant_id(currency, context.tenant_id))

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def capture_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        options.merge(get_merchant_id(currency, context.tenant_id))
        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        options = {
          :payment_method_token => true
        }
        options.merge(get_merchant_id(currency, context.tenant_id))
        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def void_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
      end

      def credit_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        options = {
          :payment_method_token => true
        }
        options.merge(get_merchant_id(currency, context.tenant_id))
        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        options.merge(get_merchant_id(currency, context.tenant_id))
        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
      end

      def get_payment_info(kb_account_id, kb_payment_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_id, properties, context)
      end

      def search_payments(search_key, offset, limit, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        options.merge(get_merchant_id(currency, context.tenant_id))
        properties = merge_properties(properties, options)
        super(search_key, offset, limit, properties, context)
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
        braintree_customer_id = find_value_from_properties(payment_method_props.properties, :customer) ||
          BraintreeBluePaymentMethod.braintree_customer_id_from_kb_account_id(kb_account_id, context.tenant_id)

        options = {
          :payment_method_nonce => find_value_from_properties(payment_method_props.properties, :payment_method_nonce),
          :customer => braintree_customer_id,
          :company => kb_account_id
        }

        if ::Killbill::Plugin::ActiveMerchant::Utils.normalized(options, :skip_gw)
          # See https://github.com/killbill/killbill-braintree-blue-plugin/pull/4
          options[:token] = find_value_from_properties(payment_method_props.properties, :token)
        elsif find_value_from_properties(payment_method_props.properties, :cc_number).blank? &&
             !find_value_from_properties(payment_method_props.properties, :token).blank?
          pm_props_hsh = properties_to_hash(payment_method_props.properties)

          # Pass 'token' (along with CC details) or 'payment_method_nonce'
          # For convenience, we translate 'token' into 'payment_method_nonce'
          # Note: we remove the token because the Braintree AM implementation always requires a CreditCard object
          options[:payment_method_nonce] = pm_props_hsh.delete(:token)

          payment_method_props = Killbill::Plugin::Model::PaymentMethodPlugin.new
          payment_method_props.properties = hash_to_properties(pm_props_hsh)
        end

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, properties, context)
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, kb_payment_method_id, properties, context)
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        # TODO
      end

      def get_payment_methods(kb_account_id, refresh_from_gateway, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(kb_account_id, refresh_from_gateway, properties, context)
      end

      def search_payment_methods(search_key, offset, limit, properties, context)
        # Pass extra parameters for the gateway here
        options = {}

        properties = merge_properties(properties, options)
        super(search_key, offset, limit, properties, context)
      end

      def reset_payment_methods(kb_account_id, payment_methods, properties, context)
        super
      end

      def build_form_descriptor(kb_account_id, descriptor_fields, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        properties = merge_properties(properties, options)

        # Add your custom static hidden tags here
        options = {
            #:token => config[:braintree_blue][:token]
        }
        descriptor_fields = merge_properties(descriptor_fields, options)

        super(kb_account_id, descriptor_fields, properties, context)
      end

      def process_notification(notification, properties, context)
        # Pass extra parameters for the gateway here
        options = {}
        properties = merge_properties(properties, options)

        super(notification, properties, context) do |gw_notification, service|
          # Retrieve the payment
          # gw_notification.kb_payment_id =
          #
          # Set the response body
          # gw_notification.entity =
        end
      end

      def get_merchant_id(currency, kb_tenant_id=nil)
        config = ::Killbill::Plugin::ActiveMerchant.config(kb_tenant_id)
        options = {}
        if config[:braintree_blue][:multicurrency]
          multicurrency = config[:multicurrency] || {}
          case currency
            when "USD"
              options = {:merchant_account_id => multicurrency[:USD]}
            when "EUR"
              options = {:merchant_account_id => multicurrency[:EUR]}
            when "PLN"
              options = {:merchant_account_id => multicurrency[:PLN]}
          end
        end
        options
      end
    end
  end
end
