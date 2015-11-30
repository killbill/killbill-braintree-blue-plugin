require 'spec_helper'

ActiveMerchant::Billing::Base.mode = :test

describe Killbill::BraintreeBlue::PaymentPlugin do

  include ::Killbill::Plugin::ActiveMerchant::RSpec

  before(:each) do
    ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.delete_all
    ::Killbill::BraintreeBlue::BraintreeBlueResponse.delete_all
    ::Killbill::BraintreeBlue::BraintreeBlueTransaction.delete_all

    @plugin = build_plugin(::Killbill::BraintreeBlue::PaymentPlugin, 'braintree_blue')
    @plugin.start_plugin

    @call_context = build_call_context

    @properties = []
    pm_overrides = {
        # ActiveMerchant wants zip to be a string
        :zip => '12345',
        :cc_verification_value => 123
    }
    @pm         = create_payment_method(::Killbill::BraintreeBlue::BraintreeBluePaymentMethod, nil, @call_context.tenant_id, @properties, pm_overrides)
    @amount     = BigDecimal.new('100')
    @currency   = 'USD'

    kb_payment_id = SecureRandom.uuid
    1.upto(6) do
      @kb_payment = @plugin.kb_apis.proxied_services[:payment_api].add_payment(kb_payment_id)
    end
  end

  after(:each) do
    @plugin.stop_plugin
  end

  # See https://github.com/killbill/killbill-braintree-blue-plugin/issues/3
  it 'should be able to add multiple cards to the same customer' do
    kb_account_id = SecureRandom.uuid
    kb_tenant_id = @call_context.tenant_id
    ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id).should be_nil

    properties = []
    pm_overrides = {
        :zip => '12345',
        :cc_verification_value => 123
    }
    create_payment_method(::Killbill::BraintreeBlue::BraintreeBluePaymentMethod, kb_account_id, kb_tenant_id, properties, pm_overrides.dup)
    b_customer_id = ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id)
    b_customer_id.should_not be_nil

    # Add a second card on the same account (same Braintree customer)
    pm_overrides[:cc_number] = '4111111111111111'
    create_payment_method(::Killbill::BraintreeBlue::BraintreeBluePaymentMethod, kb_account_id, kb_tenant_id, properties, pm_overrides.dup)
    ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id).should == b_customer_id

    pms = @plugin.get_payment_methods(kb_account_id, false, properties, @call_context)
    pms.size.should == 2

    # Verify tokens are different, and don't match the Braintree customer id
    pm1 = @plugin.get_payment_method_detail(kb_account_id, pms[0].payment_method_id, properties, @call_context)
    pm2 = @plugin.get_payment_method_detail(kb_account_id, pms[1].payment_method_id, properties, @call_context)
    pm1.external_payment_method_id.should_not == pm2.external_payment_method_id
    pm1.external_payment_method_id.should_not == b_customer_id
    pm2.external_payment_method_id.should_not == b_customer_id

    # Add a third card on the same account (same Braintree customer)
    pm_overrides[:cc_number] = '5555555555554444'
    create_payment_method(::Killbill::BraintreeBlue::BraintreeBluePaymentMethod, kb_account_id, kb_tenant_id, properties, pm_overrides.dup)
    ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.braintree_customer_id_from_kb_account_id(kb_account_id, kb_tenant_id).should == b_customer_id

    pms = @plugin.get_payment_methods(kb_account_id, false, properties, @call_context)
    pms.size.should == 3

    # Verify tokens are different, and don't match the Braintree customer id
    pm1 = @plugin.get_payment_method_detail(kb_account_id, pms[0].payment_method_id, properties, @call_context)
    pm2 = @plugin.get_payment_method_detail(kb_account_id, pms[1].payment_method_id, properties, @call_context)
    pm3 = @plugin.get_payment_method_detail(kb_account_id, pms[2].payment_method_id, properties, @call_context)
    pm1.external_payment_method_id.should_not == pm2.external_payment_method_id
    pm1.external_payment_method_id.should_not == pm3.external_payment_method_id
    pm2.external_payment_method_id.should_not == pm3.external_payment_method_id
    pm1.external_payment_method_id.should_not == b_customer_id
    pm2.external_payment_method_id.should_not == b_customer_id
    pm3.external_payment_method_id.should_not == b_customer_id
  end

  it 'should be able to create a customer with a nonce' do
    kb_account_id = SecureRandom.uuid
    kb_payment_method_id = SecureRandom.uuid

    info = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
    info.properties = []
    info.properties << build_property('token', 'ABCDEF')
    info.properties << build_property('cc_first_name', 'John')
    info.properties << build_property('cc_last_name', 'Doe')

    begin
      @plugin.add_payment_method(kb_account_id, kb_payment_method_id, info, true, [], @call_context)
      fail('it should not accept a random nonce')
    rescue => e
      # TODO Could we generate a valid nonce?
      e.message.starts_with?('Unknown payment_method_nonce.').should be_true
    end
  end

  it 'should be able to charge a Credit Card directly' do
    properties = build_pm_properties(nil,
                                     {
                                         # ActiveMerchant wants zip to be a string
                                         :zip => '12345',
                                         :cc_verification_value => 123
                                     })

    # We created the payment method, hence the rows
    Killbill::BraintreeBlue::BraintreeBlueResponse.all.size.should == 1
    Killbill::BraintreeBlue::BraintreeBlueTransaction.all.size.should == 0

    payment_response = @plugin.purchase_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == @amount
    payment_response.transaction_type.should == :PURCHASE

    responses = Killbill::BraintreeBlue::BraintreeBlueResponse.all
    responses.size.should == 2
    responses[0].api_call.should == 'add_payment_method'
    responses[0].message.should == 'OK'
    responses[1].api_call.should == 'purchase'
    responses[1].message.should == '1000 Approved'
    transactions = Killbill::BraintreeBlue::BraintreeBlueTransaction.all
    transactions.size.should == 1
    transactions[0].api_call.should == 'purchase'
  end

  # TODO Settlement?
  xit 'should be able to charge and refund' do
    payment_response = @plugin.purchase_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == @amount
    payment_response.transaction_type.should == :PURCHASE

    # Try a full refund
    refund_response = @plugin.refund_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[1].id, @pm.kb_payment_method_id, @amount, @currency, @properties, @call_context)
    refund_response.status.should eq(:PROCESSED), refund_response.gateway_error
    refund_response.amount.should == @amount
    refund_response.transaction_type.should == :REFUND
  end

  # TODO Settlement?
  xit 'should be able to auth, capture and refund' do
    payment_response = @plugin.authorize_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == @amount
    payment_response.transaction_type.should == :AUTHORIZE

    # Try multiple partial captures
    partial_capture_amount = BigDecimal.new('10')
    1.upto(3) do |i|
      payment_response = @plugin.capture_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[i].id, @pm.kb_payment_method_id, partial_capture_amount, @currency, @properties, @call_context)
      payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
      payment_response.amount.should == partial_capture_amount
      payment_response.transaction_type.should == :CAPTURE
    end

    # Try a partial refund
    refund_response = @plugin.refund_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[4].id, @pm.kb_payment_method_id, partial_capture_amount, @currency, @properties, @call_context)
    refund_response.status.should eq(:PROCESSED), refund_response.gateway_error
    refund_response.amount.should == partial_capture_amount
    refund_response.transaction_type.should == :REFUND

    # Try to capture again
    payment_response = @plugin.capture_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[5].id, @pm.kb_payment_method_id, partial_capture_amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == partial_capture_amount
    payment_response.transaction_type.should == :CAPTURE
  end

  it 'should be able to auth and void' do
    payment_response = @plugin.authorize_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == @amount
    payment_response.transaction_type.should == :AUTHORIZE

    payment_response = @plugin.void_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[1].id, @pm.kb_payment_method_id, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.transaction_type.should == :VOID
  end

  it 'should be able to auth, partial capture and void' do
    payment_response = @plugin.authorize_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[0].id, @pm.kb_payment_method_id, @amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == @amount
    payment_response.transaction_type.should == :AUTHORIZE

    partial_capture_amount = BigDecimal.new('10')
    payment_response       = @plugin.capture_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[1].id, @pm.kb_payment_method_id, partial_capture_amount, @currency, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.amount.should == partial_capture_amount
    payment_response.transaction_type.should == :CAPTURE

    payment_response = @plugin.void_payment(@pm.kb_account_id, @kb_payment.id, @kb_payment.transactions[2].id, @pm.kb_payment_method_id, @properties, @call_context)
    payment_response.status.should eq(:PROCESSED), payment_response.gateway_error
    payment_response.transaction_type.should == :VOID
  end
end
