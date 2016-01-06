killbill-braintree-plugin
=========================

Plugin was first developed by Ardura sp. z o.o.
See original repo https://bitbucket.org/safekiddo/killbill-braintree-blue-plugin.git

We cloned the repo to have it on github along with the other payment plugins supported on Kill Bill.
It is advisable to also check for latest commit from original repo before using.

Kill Bill compatibility
-----------------------

| Plugin version | Kill Bill version |
| -------------: | ----------------: |
| 0.0.y          | 0.14.z            |
| 0.1.y          | 0.15.z            |
| 0.2.y          | 0.16.z            |

Requirements
------------

The plugin needs a database. The latest version of the schema can be found [here](https://github.com/killbill/killbill-braintree-blue-plugin/blob/master/db/ddl.sql).

Configuration
-------------

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: text/plain' \
     -d ':braintree_blue:
  :merchant_id: ABC
  :public_key: DEF
  :private_key: GHI' \
     http://127.0.0.1:8080/1.0/kb/tenants/uploadPluginConfig/killbill-braintree_blue
```

To go to production, create a `braintree_blue.yml` configuration file under `/var/tmp/bundles/plugins/ruby/killbill-braintree-blue/x.y.z/` containing the following:

```
:braintree_blue:
  :test: false
```

Usage
-----

To create a customer and tokenize a credit card:

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: application/json' \
     -d '{
       "pluginName": "killbill-braintree_blue",
       "pluginInfo": {
         "properties": [
           {
             "key": "ccFirstName",
             "value": "John"
           },
           {
             "key": "ccLastName",
             "value": "Doe"
           },
           {
             "key": "address1",
             "value": "5th Street"
           },
           {
             "key": "city",
             "value": "San Francisco"
           },
           {
             "key": "zip",
             "value": "94111"
           },
           {
             "key": "state",
             "value": "CA"
           },
           {
             "key": "country",
             "value": "US"
           },
           {
             "key": "ccExpirationMonth",
             "value": 12
           },
           {
             "key": "ccExpirationYear",
             "value": 2017
           },
           {
             "key": "ccNumber",
             "value": "4111111111111111"
           }
         ]
       }
     }' \
     "http://127.0.0.1:8080/1.0/kb/accounts/<ACCOUNT_ID>/paymentMethods?isDefault=true"
```

The token can then be used for payments:

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: application/json' \
     -d '{
       "transactionType": "AUTHORIZE",
       "amount": 5
     }' \
     http://127.0.0.1:8080/1.0/kb/accounts/<ACCOUNT_ID>/payments
```

Alternatively, if you are using the JS v2 SDK, generate a nonce as follows:

```
<!DOCTYPE html>
<html>
<head>
  <script src="https://js.braintreegateway.com/v2/braintree.js"></script>
</head>
<body>
  <script>
    var client = new braintree.api.Client({clientToken: token});

    client.tokenizeCard({
      number: "4111111111111111",
      expirationDate: "10/20"
    }, function (err, nonce) {
      console.log(nonce);
    });
  </script>
</body>
</html>
```

where `token` is the server-side generated client token. For convenience, the plugin provides an endpoint to generate it:

```
curl http://127.0.0.1:8080/plugins/killbill-braintree_blue/token?kb_tenant_id=<TENANT_ID>
```

You can then create the customer with the nonce:

```
curl -v \
     -X POST \
     -u admin:password \
     -H 'X-Killbill-ApiKey: bob' \
     -H 'X-Killbill-ApiSecret: lazar' \
     -H 'X-Killbill-CreatedBy: admin' \
     -H 'Content-Type: application/json' \
     -d '{
       "pluginName": "killbill-braintree_blue",
       "pluginInfo": {
         "properties": [
           {
             "key": "ccFirstName",
             "value": "John"
           },
           {
             "key": "ccLastName",
             "value": "Doe"
           },
           {
             "key": "address1",
             "value": "5th Street"
           },
           {
             "key": "city",
             "value": "San Francisco"
           },
           {
             "key": "zip",
             "value": "94111"
           },
           {
             "key": "state",
             "value": "CA"
           },
           {
             "key": "country",
             "value": "US"
           },
           {
             "key": "token",
             "value": "<NONCE>"
           }
         ]
       }
     }' \
     "http://127.0.0.1:8080/1.0/kb/accounts/<ACCOUNT_ID>/paymentMethods?isDefault=true"
```

Note that you cannot add a second card on an existing customer using a nonce.

Plugin properties
-----------------

| Key                          | Description                                                       |
| ---------------------------: | ----------------------------------------------------------------- |
| skip_gw                      | If true, skip the call to Braintree                               |
| payment_processor_account_id | Config entry name of the merchant account to use                  |
| external_key_as_order_id     | If true, set the payment external key as the Braintree order id   |
| customer                     | Braintree customer id                                             |
| payment_method_nonce         | Payment method nonce                                              |
| token                        | Braintree token                                                   |
| cc_first_name                | Credit card holder first name                                     |
| cc_last_name                 | Credit card holder last name                                      |
| cc_type                      | Credit card brand                                                 |
| cc_expiration_month          | Credit card expiration month                                      |
| cc_expiration_year           | Credit card expiration year                                       |
| cc_verification_value        | CVC/CVV/CVN                                                       |
| email                        | Purchaser email                                                   |
| address1                     | Billing address first line                                        |
| address2                     | Billing address second line                                       |
| city                         | Billing address city                                              |
| zip                          | Billing address zip code                                          |
| state                        | Billing address state                                             |
| country                      | Billing address country                                           |
| eci                          | Network tokenization attribute                                    |
| payment_cryptogram           | Network tokenization attribute                                    |
| transaction_id               | Network tokenization attribute                                    |
| payment_instrument_name      | ApplePay tokenization attribute                                   |
| payment_network              | ApplePay tokenization attribute                                   |
| transaction_identifier       | ApplePay tokenization attribute                                   |
