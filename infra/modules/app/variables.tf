variable "project_id" {
  type        = string
  description = "Google CloudのプロジェクトID"
}

variable "application_id_suffix" {
  type        = string
  description = "iOS、AndroidアプリにおけるアプリケーションID等の接尾辞"
}

variable "apple_team_id" {
  type        = string
  description = "Apple開発者アカウントのチームID"
}

variable "android_app_sha1_hashes" {
  type        = list(string)
  description = "AndroidアプリのSHA-1ハッシュリスト"
}
