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

