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

# IAP token is inserted and passed via the x-goog-iap-jwt-assertion: "..."
#  Example: eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjBvZUxjUSJ9.eyJhdWQiOiIvcHJvamVjdHMvMzM5MDQ2MjIzODYxL2dsb2JhbC9iYWNrZW5kU2VydmljZXMvODg4NjE3ODA2NTAzOTUxMTMxNyIsImVtYWlsIjoiZGlzbGFAZ29vZ2xlLmNvbSIsImV4cCI6MTYwNTY2MDkwOSwiaGQiOiJnb29nbGUuY29tIiwiaWF0IjoxNjA1NjYwMzA5LCJpc3MiOiJodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFwIiwic3ViIjoiYWNjb3VudHMuZ29vZ2xlLmNvbToxMTEzMzE1MDYxMDA4MjQ2MDA5MDEifQ.a3RFsMAx81RY4m_J3cCZkB4rCYqD4rp9dtkL1Y8PMF-SjhUS65_ebeqNZhqlK7Ba6S8_AwbOXGZx6xpOj9l7PA
#  Decodes to:
#    {
#      "aud": "/projects/1234567890/global/backendServices/1234567890123456789",
#      "email": "user@example.com",
#      "exp": 1605660909,
#      "hd": "example.com",
#      "iat": 1605660309,  "iss": "https://cloud.google.com/iap",
#      "sub": "accounts.google.com:123456789012345678901"
#    }
# This policy uses the 'hd' field of the JWT payload to allow all users in a domain.

token := {"payload": payload} {
	[header, payload, signature] := io.jwt.decode(http_request.headers["x-goog-iap-jwt-assertion"])
}

default allow = false

allowed {
	token.payload.hd == "example.com"
}

allowed {
	token.payload.hd == "example.io"
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
		"x-broker-user": split(token.payload.email, "@")[0],
		"x-broker-id-tok": sprintf("accounts.google.com:%s", [token.payload.email])
	}
  }
}
