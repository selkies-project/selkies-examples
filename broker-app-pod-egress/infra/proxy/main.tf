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

data "google_compute_subnetwork" "broker" {
  project = var.project_id
  name    = var.subnetwork_name == "" ? "broker-${var.region}" : var.subnetwork_name
  region  = var.region
}

data "template_file" "cloud-config" {
  template = "${file("${path.module}/config/cloudconfig.yaml")}"
  vars = {
    PROJECT              = var.project_id
    INTERNAL_NET_GATEWAY = data.google_compute_subnetwork.broker.gateway_address
  }
}

data "google_service_account" "proxy" {
  account_id = "broker-proxy"
}

locals {
  proxy_name = "${var.name}-proxy-${var.region}"
}

resource "google_compute_instance_template" "proxy" {
  name_prefix  = "${local.proxy_name}-"
  project      = var.project_id
  machine_type = var.machine_type
  labels       = {}
  metadata     = map("user-data", data.template_file.cloud-config.rendered)
  region       = var.region
  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete  = true
    boot         = true
    disk_size_gb = 25
  }

  service_account {
    email  = data.google_service_account.proxy.email
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  network_interface {
    network    = data.google_compute_subnetwork.broker.network
    subnetwork = data.google_compute_subnetwork.broker.name

    dynamic "access_config" {
      for_each = var.access_configs
      content {
        nat_ip       = access_config.value["nat_ip"]
        network_tier = access_config.value["network_tier"]
      }
    }
  }

  tags = [
    "allow-ssh",
    "${var.name}-proxy",
    local.proxy_name
  ]

  lifecycle {
    create_before_destroy = "true"
  }
}

module "mig" {
  source              = "terraform-google-modules/vm/google//modules/mig"
  version             = "~> 2.1.0"
  project_id          = var.project_id
  instance_template   = google_compute_instance_template.proxy.self_link
  region              = var.region
  hostname            = local.proxy_name
  autoscaling_enabled = true
  min_replicas        = var.min_replicas
  max_replicas        = var.max_replicas
  autoscaling_cpu     = var.autoscaling_cpu
  named_ports = [
    {
      name = "http",
      port = 3128
    },
    {
      name = "tproxy"
      port = 3129
    }
  ]
  health_check = {
    type                = "tcp"
    initial_delay_sec   = 60
    check_interval_sec  = 30
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 3128
    request             = ""
    request_path        = "/"
    host                = ""
  }
  network    = data.google_compute_subnetwork.broker.network
  subnetwork = data.google_compute_subnetwork.broker.self_link
}

resource "google_compute_firewall" "proxy" {
  project = var.project_id
  name    = local.proxy_name
  network = data.google_compute_subnetwork.broker.network

  allow {
    protocol = "tcp"
  }

  target_tags = [local.proxy_name]

  # Allow traffic from regional CIDR and all secondary GKE ranges.
  source_ranges = concat(list(data.google_compute_subnetwork.broker.ip_cidr_range), data.google_compute_subnetwork.broker.secondary_ip_range.*.ip_cidr_range)
}

resource "google_compute_forwarding_rule" "proxy" {
  project               = var.project_id
  name                  = local.proxy_name
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.proxy.self_link
  all_ports             = true
  network               = data.google_compute_subnetwork.broker.network
  subnetwork            = data.google_compute_subnetwork.broker.name
}

resource "google_compute_region_backend_service" "proxy" {
  project       = var.project_id
  name          = local.proxy_name
  region        = var.region
  health_checks = [google_compute_health_check.proxy.self_link]

  backend {
    group = module.mig.instance_group
  }
}

resource "google_compute_health_check" "proxy" {
  project            = var.project_id
  name               = local.proxy_name
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "3128"
  }
}

data "google_compute_region_instance_group" "proxy" {
  self_link = module.mig.instance_group
}

resource "google_compute_route" "proxy-nat" {
  name              = "${local.proxy_name}-nat"
  dest_range        = "0.0.0.0/0"
  network           = data.google_compute_subnetwork.broker.network
  next_hop_instance = data.google_compute_region_instance_group.proxy.instances[0].instance
  priority          = 800

  tags = [
    "${local.proxy_name}-nat"
  ]

  lifecycle {
    ignore_changes = [
      next_hop_instance_zone
    ]
  }
}