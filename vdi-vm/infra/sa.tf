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

# Service account used by the VMs in the same project as the broker.
resource "google_service_account" "vdi_vm_default" {
  project      = var.project_id
  account_id   = "vdi-vm-default"
  display_name = "VDI VM Default Service Account"
}

resource "google_project_iam_member" "vdi_vm_default-log_writer" {
  project = google_service_account.vdi_vm_default.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vdi_vm_default.email}"
}

resource "google_project_iam_member" "vdi_vm_default-metric_writer" {
  project = google_project_iam_member.vdi_vm_default-log_writer.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vdi_vm_default.email}"
}

resource "google_project_iam_member" "vdi_vm_default-monitoring_viewer" {
  project = google_project_iam_member.vdi_vm_default-metric_writer.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.vdi_vm_default.email}"
}

resource "google_project_iam_member" "vdi_vm_default-iap-user" {
  project = google_project_iam_member.vdi_vm_default-metric_writer.project
  role    = "roles/iap.httpsResourceAccessor"
  member  = "serviceAccount:${google_service_account.vdi_vm_default.email}"
}

# Service account used by the VDI VM controller.
resource "google_service_account" "vdi_vm_controller" {
  project      = var.project_id
  account_id   = "vdi-vm-controller"
  display_name = "VDI VM Controller Service Account"
}

resource "google_project_iam_member" "vdi_vm_controller-compute" {
  project = google_service_account.vdi_vm_controller.project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.vdi_vm_controller.email}"
}

resource "google_project_iam_member" "vdi_vm_controller-iap-tunnel" {
  project = google_service_account.vdi_vm_controller.project
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.vdi_vm_controller.email}"
}

resource "google_project_iam_member" "vdi_vm_controller-sa-user" {
  project = google_service_account.vdi_vm_controller.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.vdi_vm_controller.email}"
}

resource "google_project_iam_member" "vdi_vm_controller-secret-admin" {
  project = google_service_account.vdi_vm_controller.project
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.vdi_vm_controller.email}"
}