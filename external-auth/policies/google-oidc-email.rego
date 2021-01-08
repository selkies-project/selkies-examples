# Copyright 2020 Google LLC
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

# When using OIDC with Google Identities, the following relavent headers are passed:
#
# x-goog-authenticated-user-email: "securetoken.google.com/PROJECT_ID:EMAIL"
#   where:
#     PROJECT_ID: the project ID where Google Identity Platform is hosted from.
#     EMAIL: the email address 

token := {"payload": payload} {
	[header, payload, signature] := io.jwt.decode(http_request.headers["x-goog-iap-jwt-assertion"])
}

auth := {"email": email, "domain": domain} {
	[email, domain] := split(split(http_request.headers["x-goog-authenticated-user-email"], ":")[1], "@")
}

default allow = false

allowed {
	auth.domain == "example.com"
}

allowed {
	auth.domain == "example.net"
}

###
# Add headers to response.
#   x-broker-user: Broker will set the Template data .User property to this value.
#   x-broker-id-tok: Broker uses this value generate a unique id for user. This is also used for VirtualService routing.
###
allow = response {
  response = {
    "allowed": allowed,
    "headers": {
		"x-broker-user": split(auth.email, "@")[0],
		"x-broker-id-tok": sprintf("accounts.google.com:%s", [auth.email])
	}
  }
}
