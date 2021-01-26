# Copyright 2021 The Selkies Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package istio.authz

import input.attributes.request.http as http_request

# Get list of allowed users from configmap
# ConfigMap is loaded automatically by kube-mgmt, see: https://github.com/open-policy-agent/kube-mgmt#json-loading
# Example config map:
#   apiVersion: v1
#   kind: ConfigMap
#   metadata:
#     name: selkies-opa-users
#     namespace: opa
#     labels: openpolicyagent.org/data: opa
#   data:
#     users.json: |-
#       {
#           "allowed_users": [
#               "user@example.com"
#           ]
#       }
import data.opa["selkies-opa-users"]["users.json"].allowed_users as selkies_users

# Extract the JWT token from the request
token := {"payload": payload} {
  [header, payload, signature] := io.jwt.decode(http_request.headers["x-goog-iap-jwt-assertion"])
}

# Extract the provider from the GCIP spec
provider_name := token.payload.gcip.firebase.sign_in_provider

provider("saml.saml-provider", p) = email {
  email := p.gcip.firebase.sign_in_attributes.email
}

# Allow selkies users
allowed = true {
    some i; selkies_users[i] == provider(provider_name, token.payload)
}

# Default deny
default allowed = false

###
# Add headers to response.
#   x-goog-authenticated-user-email: compatible header with non-migrated pod-broker configurations.
#   x-broker-user: Broker will set the Template data .User property to this value.
#   x-broker-id-tok: Broker uses this value generate a unique id for user. This is also used for VirtualService routing.
###
allow = response {
  response = {
    "allowed": allowed,
    "headers": {
      "x-goog-authenticated-user-email": sprintf("accounts.google.com:%s", [provider(provider_name, token.payload)]),
		  "x-broker-user": split(provider(provider_name, token.payload), "@")[0],
		  "x-broker-id-tok": sprintf("accounts.google.com:%s", [provider(provider_name, token.payload)])
	  }
  }
}
