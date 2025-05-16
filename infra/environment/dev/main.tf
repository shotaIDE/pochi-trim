locals {
  google_project_id_suffix           = "-house-worker-dev-tf1"
  google_project_display_name_suffix = "-Dev-Terraform1"
  application_id_suffix              = ".HouseWorker.dev"
}


# module導入前のstateを、module導入後のstateに移植するために利用した設定
# しばらくmodule導入状態で運用し、問題が発生しなかったら削除する
moved {
  from = google_project.default
  to   = module.firebase.google_project.default
}

moved {
  from = google_project_service.default
  to   = module.firebase.google_project_service.default
}

moved {
  from = google_firebase_project.default
  to   = module.firebase.google_firebase_project.default
}

moved {
  from = google_firebase_apple_app.default
  to   = module.app.google_firebase_apple_app.default
}

moved {
  from = google_firebase_android_app.default
  to   = module.app.google_firebase_android_app.default
}

moved {
  from = google_identity_platform_config.auth
  to   = module.auth.google_identity_platform_config.auth
}

moved {
  from = google_firestore_database.default
  to   = module.firestore.google_firestore_database.default
}

moved {
  from = google_firebaserules_ruleset.firestore
  to   = module.firestore.google_firebaserules_ruleset.firestore
}

moved {
  from = google_firebaserules_release.firestore
  to   = module.firestore.google_firebaserules_release.firestore
}

moved {
  from = google_firestore_index.house_works
  to   = module.firestore.google_firestore_index.house_works
}

moved {
  from = google_firestore_index.work_logs
  to   = module.firestore.google_firestore_index.work_logs
}

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

module "firebase" {
  source = "../../module/firebase"

  project_id_suffix           = local.google_project_id_suffix
  project_display_name_suffix = local.google_project_display_name_suffix
  google_billing_account_id   = var.google_billing_account_id

  providers = {
    google-beta                          = google-beta
    google-beta.no_user_project_override = google-beta.no_user_project_override
  }
}

module "app" {
  source = "../../module/app"

  project_id              = module.firebase.project_id
  application_id_suffix   = local.application_id_suffix
  apple_team_id           = var.apple_team_id
  android_app_sha1_hashes = var.android_app_sha1_hashes

  depends_on = [module.firebase]
}

module "auth" {
  source = "../../module/auth"

  project_id = module.firebase.project_id

  depends_on = [module.firebase]
}

module "firestore" {
  source = "../../module/firestore"

  project_id              = module.firebase.project_id
  google_project_location = var.google_project_location
  rules_file_path         = "../../firestore.rules"

  depends_on = [module.firebase]
}
