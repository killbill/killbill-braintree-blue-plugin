module ActiveMerchant
  module Billing
    class BraintreeBlueGateway

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
          ActiveMerchant::Billing::Response.new(
              result.success?,
              message_from_result(result),
              {
                  customer_vault_id: (result.credit_card.customer_id if result.success?),
                  credit_card_token: (result.credit_card.token if result.success?)
              },
              authorization: (result.credit_card.customer_id if result.success?)
          )
        end
      end
    end
  end
end
