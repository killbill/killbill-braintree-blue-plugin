module ActiveMerchant
  module Billing
    class BraintreeBlueGateway

      # Add support for other payment methods
      def add_customer_with_credit_card(creditcard, options)
        commit do
          if options[:payment_method_nonce]
            credit_card_params = { payment_method_nonce: options[:payment_method_nonce] }
          else
            credit_card_params = {
                :credit_card => {
                    :cardholder_name => creditcard.name,
                    :number => creditcard.number,
                    :cvv => creditcard.verification_value,
                    :expiration_month => creditcard.month.to_s.rjust(2, "0"),
                    :expiration_year => creditcard.year.to_s,
                    :token => options[:credit_card_token]
                }
            }
          end
          parameters = {
              :first_name => creditcard.first_name,
              :last_name => creditcard.last_name,
              :email => scrub_email(options[:email]),
              :id => options[:customer],
          }.merge credit_card_params
          result = @braintree_gateway.customer.create(merge_credit_card_options(parameters, options))

          card_token = nil
          if result.success? && !result.customer.credit_cards.nil? && !result.customer.credit_cards[0].nil?
            card_token = result.customer.credit_cards[0].token
          end

          paypal_token = nil
          if result.success? && !result.customer.paypal_accounts.nil? && !result.customer.paypal_accounts[0].nil?
            paypal_token = result.customer.paypal_accounts[0].token
          end

          Response.new(result.success?, message_from_result(result),
                       {
                           :braintree_customer => (customer_hash(result.customer, :include_credit_cards) if result.success?),
                           :customer_vault_id => (result.customer.id if result.success?),
                           :credit_card_token => card_token,
                           :paypal_token => paypal_token,
                           # Required for BraintreeBluePaymentMethod.from_response
                           :token => card_token || paypal_token
                       },
                       :authorization => (result.customer.id if result.success?)
          )
        end
      end

      def add_credit_card_to_customer(credit_card, options)
        commit do
          if options[:payment_method_nonce]
            credit_card_params = { payment_method_nonce: options[:payment_method_nonce] }
          else
            credit_card_params = {
                token: options[:credit_card_token],
                cardholder_name: credit_card.name,
                number: credit_card.number,
                cvv: credit_card.verification_value,
                expiration_month: credit_card.month.to_s.rjust(2, "0"),
                expiration_year: credit_card.year.to_s,
            }
          end
          parameters = {
              customer_id: options[:customer],
          }.merge credit_card_params

          options[:billing_address].compact!
          parameters[:billing_address] = map_address(options[:billing_address]) unless options[:billing_address].empty?

          result = @braintree_gateway.credit_card.create(parameters)

          card_token = nil
          if result.success?
            card_token = result.credit_card.token
          end

          ActiveMerchant::Billing::Response.new(
              result.success?,
              message_from_result(result),
              {
                  customer_vault_id: (result.credit_card.customer_id if result.success?),
                  credit_card_token: card_token,
                  # Required for BraintreeBluePaymentMethod.from_response
                  token: card_token
              },
              authorization: (result.credit_card.customer_id if result.success?)
          )
        end
      end
    end
  end
end
