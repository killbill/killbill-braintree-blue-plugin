module Killbill #:nodoc:
  module BraintreeBlue #:nodoc:
    class BraintreeBlueTransaction < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction

      self.table_name = 'braintree_blue_transactions'

      belongs_to :braintree_blue_response

    end
  end
end
