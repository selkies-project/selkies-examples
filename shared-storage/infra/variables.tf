/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {}

variable "name" {
  default = "broker"
}

variable "region" {
  default = "us-west1"
}

variable "location" {
  default     = "us-west1-a"
  description = "The name of the location of the instance. This can be a region for ENTERPRISE tier instances or a zone for other tiers."
}

variable "tier" {
  default = "STANDARD"
}

variable "capacity_gb" {
  default = 1024
}