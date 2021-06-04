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

variable "region" {}

variable "name" {
  default = "broker"
}

variable "subnetwork_name" {
  description = "name of subnetwork to deploy proxy to, if not set, default will be broker-REGION"
  default     = ""
}

variable "min_replicas" {
  default = 1
}

variable "max_replicas" {
  default = 5
}

variable "machine_type" {
  default = "n1-standard-2"
}

variable "access_configs" {
  description = "access config blocks for the instance, set to [] to omit assinging an external IP."
  default = [{
    nat_ip       = ""
    network_tier = "PREMIUM"
  }]
}

variable "autoscaling_cpu" {
  description = "Autoscaling, cpu utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#cpu_utilization"
  type        = list(map(number))
  default = [{
    target = 0.5
  }]
}