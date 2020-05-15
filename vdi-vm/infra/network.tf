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

resource "google_compute_network" "vdi-vm" {
  name                    = "vdi-vm"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vdi-vm" {
  for_each      = toset(var.subnet_regions)
  name          = "vdi-vm-${each.value}"
  ip_cidr_range = "10.${2 + lookup(local.cluster_regions, each.value)}.0.0/16"
  region        = each.value
  network       = google_compute_network.vdi-vm.self_link
}

# Firewall rule to allow IAP
resource "google_compute_firewall" "allow-iap" {
  name    = "allow-iap"
  project = var.project_id
  network = google_compute_network.vdi-vm.self_link

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.235.240.0/20"
  ]
}