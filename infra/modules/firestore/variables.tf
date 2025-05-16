variable "project_id" {
  type        = string
  description = "Google CloudのプロジェクトID"
}

variable "location_id" {
  type        = string
  description = "Firestoreのロケーション"
}

variable "rules_file_path" {
  default     = "../firestore.rules"
  type        = string
  description = "Firestoreルールファイルのパス"
}
