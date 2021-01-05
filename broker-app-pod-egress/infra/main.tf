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

module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = var.project_id
  prefix     = var.name
  names      = ["proxy"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/storage.objectViewer",
  ]
}

// Static route to allow instance to bypass NAT for Private Google Access
resource "google_compute_route" "proxy-pga" {
  project          = var.project_id
  name             = "${var.name}-proxy-pga"
  dest_range       = "199.36.153.4/30"
  network          = data.google_compute_network.broker.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
  tags             = ["broker-proxy"]
}

// Static route to allow instance to bypass NAT for internal metadata server
resource "google_compute_route" "proxy-metadata" {
  project          = var.project_id
  name             = "${var.name}-proxy-metadata"
  dest_range       = "169.254.169.254/32"
  network          = data.google_compute_network.broker.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
  tags             = ["broker-proxy"]
}

# Firewall rule to allow IAP
resource "google_compute_firewall" "allow-iap" {
  name    = "allow-iap-broker-proxy"
  project = var.project_id
  network = data.google_compute_network.broker.name

  allow {
    protocol = "tcp"
  }

  target_tags = ["broker-proxy"]

  source_ranges = [
    "35.235.240.0/20"
  ]
}