variable "project_id" {
  type        = string
  description = "Google CloudのプロジェクトID"
}

variable "google_project_location" {
  type        = string
  description = "Google Cloudプロジェクトのロケーション"
}

variable "rules_file_path" {
  default     = "../firestore.rules"
  type        = string
  description = "Firestoreルールファイルのパス"
}
