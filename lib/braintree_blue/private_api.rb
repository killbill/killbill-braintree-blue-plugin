module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class PrivatePaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PrivatePaymentPlugin
      def initialize(session = {})
        super(:braintree_blue,
              ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod,
              ::Killbill::BraintreeBlue::BraintreeBlueTransaction,
              ::Killbill::BraintreeBlue::BraintreeBlueResponse,
              session)
      end
    end
  end
end
