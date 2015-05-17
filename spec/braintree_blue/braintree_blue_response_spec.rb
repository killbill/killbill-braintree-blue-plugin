require 'spec_helper'

describe Killbill::BraintreeBlue::BraintreeBlueResponse do
  before :all do
    Killbill::BraintreeBlue::BraintreeBlueResponse.delete_all
  end

  it 'should search all fields' do
    kb_account_id = '33-44-55-66'
    kb_tenant_id = '77-88-99-00'

    do_search('foo', kb_tenant_id).size.should == 0

    pm = Killbill::BraintreeBlue::BraintreeBlueResponse.create :api_call => 'charge',
                                                               :kb_payment_id => '11-22-33-44',
                                                               :kb_account_id => kb_account_id,
                                                               :kb_tenant_id => kb_tenant_id,
                                                               :authorization => 'aa-bb-cc-dd',
                                                               :params_braintree_customer_id => '123456',
                                                               :params_braintree_customer_credit_card_token => '38102343',
                                                               :success => true,
                                                               :created_at => Time.now,
                                                               :updated_at => Time.now
    # Not successful
    ignored2 = Killbill::BraintreeBlue::BraintreeBlueResponse.create :api_call => 'charge',
                                                                     :kb_payment_id => pm.kb_payment_id,
                                                                     :kb_account_id => kb_account_id,
                                                                     :kb_tenant_id => kb_tenant_id,
                                                                     :authorization => pm.authorization,
                                                                     :params_braintree_customer_id => pm.params_braintree_customer_id,
                                                                     :params_braintree_customer_credit_card_token => pm.params_braintree_customer_credit_card_token,
                                                                     :success => false,
                                                                     :created_at => Time.now,
                                                                     :updated_at => Time.now

    do_search('foo', kb_tenant_id).size.should == 0
    do_search(pm.authorization, kb_tenant_id).size.should == 1
    do_search(pm.params_braintree_customer_id, kb_tenant_id).size.should == 1
    do_search(pm.params_braintree_customer_credit_card_token, kb_tenant_id).size.should == 1

    pm2 = Killbill::BraintreeBlue::BraintreeBlueResponse.create :api_call => 'charge',
                                                                :kb_payment_id => '11-22-33-44',
                                                                :kb_account_id => kb_account_id,
                                                                :kb_tenant_id => kb_tenant_id,
                                                                :authorization => 'AA-BB-CC-DD',
                                                                :params_braintree_customer_id => '1234567',
                                                                :params_braintree_customer_credit_card_token => pm.params_braintree_customer_credit_card_token,
                                                                :success => true,
                                                                :created_at => Time.now,
                                                                :updated_at => Time.now

    do_search('foo', kb_tenant_id).size.should == 0
    do_search(pm.authorization, kb_tenant_id).size.should == 1
    do_search(pm.params_braintree_customer_id, kb_tenant_id).size.should == 1
    do_search(pm.params_braintree_customer_credit_card_token, kb_tenant_id).size.should == 2
    do_search(pm2.authorization, kb_tenant_id).size.should == 1
    do_search(pm2.params_braintree_customer_id, kb_tenant_id).size.should == 1
    do_search(pm2.params_braintree_customer_credit_card_token, kb_tenant_id).size.should == 2
  end

  private

  def do_search(search_key, kb_tenant_id)
    pagination = Killbill::BraintreeBlue::BraintreeBlueResponse.search(search_key, kb_tenant_id)
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end
end