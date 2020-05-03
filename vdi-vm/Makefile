# Copyright 2019 Google LLC
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

all: images manifests examples

.PHONY: images manifests examples

REGION := us-west1
ACTION := apply

images:
	cd images && gcloud builds submit

manifests:
	gcloud builds submit --substitutions=_REGION=$(REGION),_ACTION=$(ACTION)

example-image-%:
	cd examples/$*/image && gcloud builds submit

example-%:
	cd examples/$* && gcloud builds submit --substitutions=_REGION=$(REGION),_ACTION=${ACTION}

examples: example-win2k19 example-centos7 example-ubuntu