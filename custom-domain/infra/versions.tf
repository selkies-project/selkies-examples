terraform {
  backend "gcs" {}
  required_version = ">= 1.2.3"
  required_providers {
    google = "~> 4.25.0, <4.25.6"
  }
}