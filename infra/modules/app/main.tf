terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
      configuration_aliases = []
    }
  }
}

resource "google_firebase_apple_app" "default" {
  provider = google-beta

  project      = var.project_id
  display_name = "iOS"
  bundle_id    = var.application_id
  team_id      = var.ios_app_team_id
}

resource "google_firebase_android_app" "default" {
  provider = google-beta

  project      = var.project_id
  display_name = "Android"
  package_name = var.application_id
  sha1_hashes  = var.android_app_sha1_hashes
}
