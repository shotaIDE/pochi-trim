resource "google_firestore_database" "default" {
  project                 = google_project.default.project_id
  name                    = "(default)"
  location_id             = var.google_project_location
  type                    = "FIRESTORE_NATIVE"
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy         = "ABANDON"

  depends_on = [
    google_project_service.default,
  ]
}

resource "google_firebaserules_ruleset" "firestore" {
  provider = google-beta
  project  = google_project.default.project_id
  source {
    files {
      name    = "firestore.rules"
      content = file("./firestore.rules")
    }
  }

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firebaserules_release" "firestore" {
  provider     = google-beta
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.name
  project      = google_project.default.project_id

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firestore_index" "house_works" {
  project    = google_project.default.project_id
  collection = "houseWorks"
  database   = google_firestore_database.default.name

  fields {
    field_path = "title"
    order      = "ASCENDING"
  }

  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firestore_index" "work_logs" {
  project    = google_project.default.project_id
  collection = "workLogs"
  database   = google_firestore_database.default.name

  fields {
    field_path = "title"
    order      = "ASCENDING"
  }

  fields {
    field_path = "completedAt"
    order      = "DESCENDING"
  }

  depends_on = [
    google_firestore_database.default,
  ]
}
