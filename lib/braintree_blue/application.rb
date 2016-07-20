# -- encoding : utf-8 --

set :views, File.expand_path(File.dirname(__FILE__) + '/views')

require 'braintree'

include Killbill::Plugin::ActiveMerchant::Sinatra

configure do
  # Usage: rackup -Ilib -E test
  if development? or test?
    # Make sure the plugin is initialized
    plugin              = ::Killbill::BraintreeBlue::PaymentPlugin.new
    plugin.logger       = Logger.new(STDOUT)
    plugin.logger.level = Logger::INFO
    plugin.conf_dir     = File.dirname(File.dirname(__FILE__)) + '/..'
    plugin.start_plugin
  end
end

helpers do
  def plugin(session = {})
    ::Killbill::BraintreeBlue::PrivatePaymentPlugin.new(session)
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-braintree_blue/token
get '/plugins/killbill-braintree_blue/token', :provides => 'json' do
  kb_tenant_id = request.GET['kb_tenant_id']
  kb_tenant = request.env['killbill_tenant']
  kb_tenant_id ||= kb_tenant.id.to_s unless kb_tenant.nil?

  environment = request.GET['environment'] || 'sandbox'
  customer_id = request.GET['customer_id']

  bconfig = (config(kb_tenant_id) || {})[:braintree_blue] || {}

  Braintree::Configuration.environment = environment.to_sym
  Braintree::Configuration.merchant_id = bconfig[:merchant_id]
  Braintree::Configuration.private_key = bconfig[:private_key]
  Braintree::Configuration.public_key = bconfig[:public_key]

  { :client_token => Braintree::ClientToken.generate(:customer_id => customer_id) }.to_json
end

# curl -v http://127.0.0.1:9292/plugins/killbill-braintree_blue/form
get '/plugins/killbill-braintree_blue/form', :provides => 'html' do
  order_id   = request.GET['order_id']
  account_id = request.GET['account_id']
  options    = {
      :amount           => request.GET['amount'],
      :currency         => request.GET['currency'],
      :test             => request.GET['test'],
      :credential2      => request.GET['credential2'],
      :credential3      => request.GET['credential3'],
      :credential4      => request.GET['credential4'],
      :country          => request.GET['country'],
      :account_name     => request.GET['account_name'],
      :transaction_type => request.GET['transaction_type'],
      :authcode         => request.GET['authcode'],
      :notify_url       => request.GET['notify_url'],
      :return_url       => request.GET['return_url'],
      :redirect_param   => request.GET['redirect_param'],
      :forward_url      => request.GET['forward_url']
  }

  @form = plugin(session).payment_form_for(order_id, account_id, :braintree_blue, options) do |service|
    # Add your custom hidden tags here, e.g.
    #service.token = config[:braintree_blue][:token]
    submit_tag 'Submit'
  end

  erb :form
end

# curl -v http://127.0.0.1:9292/plugins/killbill-braintree_blue/1.0/pms/1
get '/plugins/killbill-braintree_blue/1.0/pms/:id', :provides => 'json' do
  if pm = ::Killbill::BraintreeBlue::BraintreeBluePaymentMethod.find_by_id(params[:id].to_i)
    pm.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-braintree_blue/1.0/transactions/1
get '/plugins/killbill-braintree_blue/1.0/transactions/:id', :provides => 'json' do
  if transaction = ::Killbill::BraintreeBlue::BraintreeBlueTransaction.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-braintree_blue/1.0/responses/1
get '/plugins/killbill-braintree_blue/1.0/responses/:id', :provides => 'json' do
  if transaction = ::Killbill::BraintreeBlue::BraintreeBlueResponse.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end
