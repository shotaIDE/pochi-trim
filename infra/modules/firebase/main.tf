terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
      configuration_aliases = [
        google-beta.no_user_project_override
      ]
    }
  }
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
  for_each = toset([
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtasks.googleapis.com",
    "firebase.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasestorage.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "identitytoolkit.googleapis.com",
    "serviceusage.googleapis.com",
    "sts.googleapis.com",
  ])
  service = each.key

  disable_on_destroy = false
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = google_project.default.project_id

  depends_on = [
    google_project_service.default
  ]
}
