require 'spec_helper'

describe Killbill::BraintreeBlue::PaymentPlugin do

  include ::Killbill::Plugin::ActiveMerchant::RSpec

  before(:each) do
    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'braintree_blue.yml'), 'w+')
      file.write(<<-eos)
:braintree_blue:
  :test: true
# As defined by spec_helper.rb
:database:
  :adapter: 'sqlite3'
  :database: 'test.db'
      eos
      file.close

      @plugin = build_plugin(::Killbill::BraintreeBlue::PaymentPlugin, 'braintree_blue', File.dirname(file))

      # Start the plugin here - since the config file will be deleted
      @plugin.start_plugin
    end
  end

  it 'should start and stop correctly' do
    @plugin.stop_plugin
  end

=begin
  it 'should generate forms correctly' do
    kb_account_id = SecureRandom.uuid
    kb_tenant_id  = SecureRandom.uuid
    context       = @plugin.kb_apis.create_context(kb_tenant_id)
    fields        = @plugin.hash_to_properties({
                                                   :order_id => '1234',
                                                   :amount   => 10
                                               })
    form          = @plugin.build_form_descriptor kb_account_id, fields, [], context

    form.kb_account_id.should == kb_account_id
    form.form_method.should == 'POST'
    form.form_url.should == 'https://braintree_blue.com'

    form_fields = @plugin.properties_to_hash(form.form_fields)
  end

  it 'should receive notifications correctly' do
    description    = 'description'

    kb_tenant_id = SecureRandom.uuid
    context      = @plugin.kb_apis.create_context(kb_tenant_id)
    properties   = @plugin.hash_to_properties({ :description => description })

    notification    = ""
    gw_notification = @plugin.process_notification notification, properties, context
  end
=end
end
