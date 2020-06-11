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

data "google_compute_network" "broker" {
  project = var.project_id
  name    = var.name
}

data "google_compute_subnetwork" "broker" {
  self_link = data.google_compute_network.broker.subnetworks_self_links[0]
}

locals {
  cluster_ip_num = split(".", data.google_compute_subnetwork.broker.ip_cidr_range)[1]
  storage_cidr   = "10.${200 + local.cluster_ip_num}.0.0/29"
}

resource "google_filestore_instance" "shared-storage" {
  name = "${var.name}-shared-storage-${var.zone}"
  zone = var.zone
  tier = var.tier

  file_shares {
    capacity_gb = var.capacity_gb
    name        = "data"
  }

  networks {
    network           = data.google_compute_network.broker.name
    modes             = ["MODE_IPV4"]
    reserved_ip_range = local.storage_cidr
  }

  timeouts {
    create = "20m"
  }
}