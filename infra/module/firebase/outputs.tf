output "project_id" {
  value = google_project.default.project_id
}

output "project" {
  value = google_project.default
}

output "firebase_project" {
  value = google_firebase_project.default
}
