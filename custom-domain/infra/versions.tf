terraform {
  backend "gcs" {}
  required_version = ">= 0.12"
  required_providers {
    google = "~> 3.57"
  }
}