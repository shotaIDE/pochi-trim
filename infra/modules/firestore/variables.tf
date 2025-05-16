variable "project_id" {
  description = "Google CloudのプロジェクトID"
  type        = string
}

variable "location_id" {
  description = "Firestoreのロケーション"
  type        = string
}

variable "rules_file_path" {
  description = "Firestoreルールファイルのパス"
  type        = string
  default     = "../firestore.rules"
}
