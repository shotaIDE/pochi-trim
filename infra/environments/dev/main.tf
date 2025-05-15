locals {
  google_project_id           = "colomney-house-worker-dev-tf1"
  google_project_display_name = "PochiTrim-Dev-Terraform1"
  application_id              = "ide.shota.colomney.HouseWorker.dev"
}

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
    }
  }
}

module "firebase" {
  source = "../../modules/firebase"

  project_id           = local.google_project_id
  project_display_name = local.google_project_display_name
  billing_account_id   = var.google_billing_account_id
}

module "firestore" {
  source = "../../modules/firestore"

  project_id      = module.firebase.project_id
  location_id     = var.google_project_location
  rules_file_path = "../../firestore.rules"

  depends_on = [module.firebase]
}

module "auth" {
  source = "../../modules/auth"

  project_id = module.firebase.project_id

  depends_on = [module.firebase]
}

module "app" {
  source = "../../modules/app"

  project_id              = module.firebase.project_id
  application_id          = local.application_id
  ios_app_team_id         = var.ios_app_team_id
  android_app_sha1_hashes = var.firebase_android_app_sha1_hashes

  depends_on = [module.firebase]
}
