terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
    }
  }
}

provider "google-beta" {
  user_project_override = true
}

provider "google-beta" {
  alias                 = "no_user_project_override"
  user_project_override = false
}

resource "google_project" "default" {
  provider = google-beta.no_user_project_override

  name            = var.project_display_name
  project_id      = var.project_id
  billing_account = var.billing_account_id

  labels = {}
}

resource "google_project_service" "default" {
  provider = google-beta.no_user_project_override
  project  = google_project.default.project_id
  for_each = toset(var.services)
  service  = each.key

  disable_on_destroy = false
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = google_project.default.project_id

  depends_on = [
    google_project_service.default
  ]
}
