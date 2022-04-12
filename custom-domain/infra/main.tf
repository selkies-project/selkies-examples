#broker-custom-domain
resource "google_secret_manager_secret" "broker_custom_domain_secret_manager_secret" {
  count     = var.custom_domain == "" ? 0 : 1
  project   = var.project_id
  secret_id = "broker-custom-domain"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "broker_custom_domain_secret_manager_version" {
  count       = var.custom_domain == "" ? 0 : 1
  secret      = google_secret_manager_secret.broker_custom_domain_secret_manager_secret.0.id
  secret_data = var.custom_domain
}

#broker-tfvars-lb-domains
resource "google_secret_manager_secret" "broker_lb_domains_secret_manager_secret" {
  count     = var.lb_domains == "" ? 0 : 1
  project   = var.project_id
  secret_id = "broker-tfvars-lb-domains"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "broker_lb_domains_secret_manager_version" {
  count       = var.lb_domains == "" ? 0 : 1
  secret      = google_secret_manager_secret.broker_lb_domains_secret_manager_secret.0.id
  secret_data = format("additional_ssl_certificate_domains =%s", jsonencode(toset(split(",", var.lb_domains))))
}

#broker-logout-url
resource "google_secret_manager_secret" "broker_logout_url_secret_manager_secret" {
  project   = var.project_id
  secret_id = "broker-logout-url"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "broker_logout_url_secret_manager_version" {
  secret      = google_secret_manager_secret.broker_logout_url_secret_manager_secret.id
  secret_data = var.custom_domain == "" ? "https://broker.endpoints.${var.project_id}.cloud.goog?gcp-iap-mode=GCIP_SIGNOUT" : "https://${var.custom_domain}?gcp-iap-mode=GCIP_SIGNOUT"
}