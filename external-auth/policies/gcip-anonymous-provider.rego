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

# Extract the JWT token from the request
default token = {"payload": {}}
token = {"payload": payload} {
  [header, payload, signature] := io.jwt.decode(http_request.headers["x-goog-iap-jwt-assertion"])
}

# Extract the provider from the GCIP spec
default provider = {"name": "cookie"}
provider = {"name": name} {
  name := token.payload.gcip.firebase.sign_in_provider
}

provider_email("cookie", p) = email {
  values := split(http_request.headers["cookie"], ";")
  some i; re_match("^broker_.*?=.*?#.*$", values[i])
  email := split(split(values[i], "=")[1], "#")[0]
}

provider_email("anonymous", p) = email {
  email := sprintf("anonymous@%s", p.gcip.user_id)
}

# Allow deployment type watchdog requests
allowed = true {
  regex.match("/reservation-broker/shutdown/", http_request.path)
  provider_email("cookie", token.payload) == "watchdog@localhost"
}

# Default allow
default allowed = true

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
      "x-goog-authenticated-user-email": sprintf("accounts.google.com:%s", [provider_email(provider.name, token.payload)]),
		  "x-broker-user": split(provider_email(provider.name, token.payload), "@")[0],
		  "x-broker-id-tok": sprintf("accounts.google.com:%s", [provider_email(provider.name, token.payload)])
	  }
  }
}
